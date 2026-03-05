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
    local config_file="${3:-$SCRIPT_DIR/../examples/dev.conf}"

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

    local window_name="$zone_name"

    # Create a new session or window
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -n "$window_name"
    else
        tmux new-window -t "$session_name:" -n "$window_name"
    fi

    # Get the actual window index that was just created
    local window_index=$(tmux list-windows -t "$session_name" -F "#{window_index}:#{window_name}" | grep ":$window_name$" | cut -d: -f1 | tail -1)
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

        # Build split command
        local split_cmd="tmux split-window -t \"$target\" $split_flag"

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

    # Send commands to panes
    for ((i=0; i<$pane_count; i++)); do
        local pane="${panes[$i]}"
        local pane_key="$zone_name.$pane"
        local command="${pane_command[$pane_key]}"
        local actual_index="${pane_indices[$i]}"

        if [[ -n "$command" ]]; then
            tmux send-keys -t "$target.$actual_index" "$command" C-m
        fi
    done

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
