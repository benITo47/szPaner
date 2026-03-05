#!/usr/bin/env bash

# szPaner - Spawn Zone Paner
# Creates a tmux window with predefined panes and commands from config

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the config parser
source "$SCRIPT_DIR/parse-config.sh"

# Create a zone from parsed config
spawn_zone() {
    local zone_name="$1"
    local session_name="${2:-szpaner}"
    local config_file="${3:-}"

    # Find config if not specified
    if [[ -z "$config_file" ]]; then
        for config in "$HOME/.szpaner/zones.conf" "$HOME/.config/szpaner/zones.conf" "$SCRIPT_DIR/../zones.conf"; do
            if [[ -f "$config" ]]; then
                config_file="$config"
                break
            fi
        done
    fi

    # Parse the config file
    if ! parse_config_file "$config_file"; then
        echo "Error: Failed to parse config file: $config_file" >&2
        return 1
    fi

    # Check if zone exists
    local zone_exists=false
    for zone in "${all_zones[@]}"; do
        if [[ "$zone" == "$zone_name" ]]; then
            zone_exists=true
            break
        fi
    done

    if ! $zone_exists; then
        echo "Error: Zone '$zone_name' not found in config" >&2
        echo "Available zones: ${all_zones[*]}" >&2
        return 1
    fi

    # Find next available number for this zone
    local existing_windows=$(tmux list-windows -t "$session_name" 2>/dev/null -F "#{window_name}" | grep "^${zone_name}\(-[0-9]\+\)\?$" || echo "")
    local max_num=0

    while IFS= read -r win; do
        if [[ "$win" == "$zone_name" ]]; then
            max_num=1
        elif [[ "$win" =~ ^${zone_name}-([0-9]+)$ ]]; then
            local num="${BASH_REMATCH[1]}"
            [[ $num -gt $max_num ]] && max_num=$num
        fi
    done <<< "$existing_windows"

    # Generate window name
    if [[ $max_num -eq 0 ]]; then
        local window_name="$zone_name"
    else
        local window_name="$zone_name-$((max_num + 1))"
    fi

    # Get zone working directory
    local zone_dir="${zone_working_dir[$zone_name]}"

    # Create a new session or window with working directory
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        if [[ -n "$zone_dir" ]]; then
            tmux new-session -d -s "$session_name" -n "$window_name" -c "$zone_dir"
        else
            tmux new-session -d -s "$session_name" -n "$window_name"
        fi
    else
        if [[ -n "$zone_dir" ]]; then
            tmux new-window -t "$session_name:" -n "$window_name" -c "$zone_dir"
        else
            tmux new-window -t "$session_name:" -n "$window_name"
        fi
    fi

    # Get the window index that was just created (it's the last one)
    local window_index=$(tmux list-windows -t "$session_name" -F "#{window_index}" | tail -1)
    local target="$session_name:$window_index"

    # Get panes for this zone
    local panes=(${zone_panes[$zone_name]})
    local pane_count=${#panes[@]}

    if [[ $pane_count -eq 0 ]]; then
        echo "Error: Zone '$zone_name' has no panes defined" >&2
        return 1
    fi

    # First pane already exists (pane 0)
    local current_pane_index=0

    # Create remaining panes
    for ((i=1; i<$pane_count; i++)); do
        local pane="${panes[$i]}"
        local pane_key="$zone_name.$pane"
        local split_dir="${pane_split[$pane_key]:-right}"
        local size="${pane_size[$pane_key]}"

        # Convert split direction to tmux flags
        local split_flag="-h"  # horizontal split (left/right)
        case "$split_dir" in
            down|bottom)
                split_flag="-v"  # vertical split (top/bottom)
                ;;
            right|left)
                split_flag="-h"
                ;;
        esac

        # Get pane working directory (overrides zone working_dir)
        local pane_dir="${pane_working_dir[$pane_key]}"
        [[ -z "$pane_dir" ]] && pane_dir="$zone_dir"

        # Build split command
        local split_cmd="tmux split-window -t \"$target\" $split_flag"

        # Add working directory if specified
        if [[ -n "$pane_dir" ]]; then
            split_cmd+=" -c \"$pane_dir\""
        fi

        # Add size if specified
        if [[ -n "$size" ]]; then
            # Remove % if present and use as percentage
            local size_num="${size%\%}"
            split_cmd+=" -p $size_num"
        fi

        # Execute split
        eval "$split_cmd"
    done

    # Small delay to ensure panes are ready
    sleep 0.1

    # Get actual pane indices (respects base-index setting)
    local pane_indices=($(tmux list-panes -t "$target" -F "#{pane_index}"))

    # Send commands to panes (supports multiple execute statements)
    for ((i=0; i<$pane_count; i++)); do
        local pane="${panes[$i]}"
        local pane_key="$zone_name.$pane"
        local actual_index="${pane_indices[$i]}"

        # Execute all commands for this pane
        local cmd_count=${pane_command_count[$pane_key]:-0}
        for ((j=0; j<cmd_count; j++)); do
            local command="${pane_commands[$pane_key.$j]}"
            if [[ -n "$command" ]]; then
                tmux send-keys -t "$target.$actual_index" "$command" C-m
            fi
        done
    done

    # Execute on_start hook if defined
    local on_start_cmd="${zone_on_start[$zone_name]}"
    if [[ -n "$on_start_cmd" ]]; then
        # Execute in the first pane
        tmux send-keys -t "$target.${pane_indices[0]}" "$on_start_cmd" C-m
    fi

    # Set up on_detach hook if defined
    local on_detach_cmd="${zone_on_detach[$zone_name]}"
    if [[ -n "$on_detach_cmd" ]]; then
        # Set a window-specific hook for when client detaches
        tmux set-hook -t "$target" client-detached "run-shell '$on_detach_cmd'"
    fi

    # Select the first pane
    tmux select-pane -t "$target.${pane_indices[0]}"

    # Attach or switch to session
    if [ -z "$TMUX" ]; then
        tmux attach-session -t "$session_name"
    else
        tmux switch-client -t "$session_name"
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 <zone-name> [session-name] [config-file]"
    echo ""
    echo "Arguments:"
    echo "  zone-name    Name of the zone to spawn (required)"
    echo "  session-name Tmux session name (default: szpaner)"
    echo "  config-file  Config file path (default: examples/dev.conf)"
    echo ""
    echo "Examples:"
    echo "  $0 dev"
    echo "  $0 servers my-session"
    echo "  $0 dev my-session ~/.szpaner/custom.conf"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi

    spawn_zone "$@"
fi
