#!/usr/bin/env bash

# szPaner - Save Zone
# Captures current tmux window as a zone config

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the best command representation for a pane
get_pane_command() {
    local target="$1"

    # Get current command (e.g., "nvim", "ssh user@host")
    local current_cmd=$(tmux display-message -t "$target" -p "#{pane_current_command}")

    # Try to get more detail from visible content (last line)
    local visible_cmd=$(tmux capture-pane -t "$target" -p -S -1 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//')

    # If the visible command looks like a command line (has typical prompt chars)
    if [[ "$visible_cmd" =~ ^\$|^%|^#|^\> ]]; then
        # Extract command after prompt
        local extracted=$(echo "$visible_cmd" | sed -E 's/^[$%#>][[:space:]]*//')
        if [[ -n "$extracted" && "$extracted" != "$current_cmd" ]]; then
            echo "$extracted"
            return
        fi
    fi

    # For interactive programs, just return the program name
    # Skip "bash", "zsh", etc. - those are just shells
    case "$current_cmd" in
        bash|zsh|sh|fish)
            # Shell is running, try to get what might be running in it
            if [[ -n "$visible_cmd" && "$visible_cmd" != *"$"* && "$visible_cmd" != *"%"* ]]; then
                echo "$visible_cmd"
            else
                echo ""
            fi
            ;;
        *)
            echo "$current_cmd"
            ;;
    esac
}

# Generate zone config from current window
generate_zone_config() {
    local zone_name="$1"
    local layout="$2"
    local session_name="$3"
    local window_index="$4"
    local target="$session_name:$window_index"

    # Get window working directory (from first pane)
    local window_dir=$(tmux display-message -t "$target.0" -p "#{pane_current_path}")

    # Start building config
    local config=""
    config+="# Saved zone: $zone_name ($(date +%Y-%m-%d))\n"
    config+="zone \"$zone_name\" {\n"

    # Add layout string if available
    if [[ -n "$layout" ]]; then
        config+="    layout \"$layout\"\n"
        config+="\n"
    fi

    # Get pane information
    local pane_data=$(tmux list-panes -t "$target" -F "#{pane_index}|#{pane_current_path}|#{pane_width}|#{pane_height}")

    local pane_index=0
    while IFS='|' read -r index pane_path width height; do
        local pane_name="pane$index"

        config+="    pane \"$pane_name\" {\n"

        # Add working directory if different from window dir
        if [[ "$pane_path" != "$window_dir" ]]; then
            config+="        working_dir \"$pane_path\"\n"
        fi

        # Get and add command if any
        local pane_target="$target.$index"
        local command=$(get_pane_command "$pane_target")

        if [[ -n "$command" ]]; then
            # Escape quotes in command
            command="${command//\"/\\\"}"
            config+="        execute \"$command\"\n"
        fi

        config+="    }\n"

        if [[ $pane_index -lt $(echo "$pane_data" | wc -l) ]]; then
            config+="\n"
        fi

        ((pane_index++))
    done <<< "$pane_data"

    config+="}\n"

    echo -e "$config"
}

# Check if zone name already exists in config
zone_exists() {
    local zone_name="$1"
    local config_file="$2"

    if [[ -f "$config_file" ]]; then
        grep -q "^zone \"$zone_name\"" "$config_file" 2>/dev/null
        return $?
    fi

    return 1
}

# Append zone config to file
append_to_config() {
    local config_file="$1"
    local zone_config="$2"
    local zone_name="$3"

    # Create config directory if needed
    mkdir -p "$(dirname "$config_file")"

    # Check for duplicate zone names
    if zone_exists "$zone_name" "$config_file"; then
        # Add suffix to make it unique
        local original_name="$zone_name"
        local suffix=2

        while zone_exists "$zone_name" "$config_file"; do
            zone_name="${original_name}-${suffix}"
            ((suffix++))
        done

        # Update the zone name in the config
        zone_config=$(echo -e "$zone_config" | sed "s/zone \"$original_name\"/zone \"$zone_name\"/")

        tmux display-message "Warning: Zone '$original_name' exists. Saving as '$zone_name'"
    fi

    # Append with newline separator
    echo "" >> "$config_file"
    echo -e "$zone_config" >> "$config_file"

    tmux display-message "Zone '$zone_name' saved to $config_file"
}

# Main save zone function
save_zone() {
    local zone_name="$1"

    # Validate zone name
    if [[ -z "$zone_name" ]]; then
        tmux display-message "Error: Zone name required"
        return 1
    fi

    # Check if zone name contains only valid characters
    if [[ ! "$zone_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        tmux display-message "Error: Zone name can only contain: a-z A-Z 0-9 _ -"
        return 1
    fi

    # Get current session and window
    local session_name=$(tmux display-message -p '#S')
    local window_index=$(tmux display-message -p '#I')
    local target="$session_name:$window_index"

    # Capture layout string
    local layout=$(tmux list-windows -t "$target" -F "#{window_layout}" 2>/dev/null | head -1)

    if [[ -z "$layout" ]]; then
        tmux display-message "Error: Could not capture window layout"
        return 1
    fi

    # Generate zone config
    local zone_config=$(generate_zone_config "$zone_name" "$layout" "$session_name" "$window_index")

    # Find config file
    local config_file=""
    for config in "$HOME/.config/szpaner/zones.conf" "$HOME/szpaner.conf"; do
        if [[ -f "$config" ]]; then
            config_file="$config"
            break
        fi
    done

    # Default to ~/.config/szpaner/zones.conf if no config found
    if [[ -z "$config_file" ]]; then
        config_file="$HOME/.config/szpaner/zones.conf"
    fi

    # Append to config file
    append_to_config "$config_file" "$zone_config" "$zone_name"
}

# Run if executed directly or via run-shell
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    save_zone "$1"
fi
