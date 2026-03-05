#!/usr/bin/env bash

# sz-tmux.sh - Handler for :sz command inside tmux
# Called via command-alias when user runs :sz zoneName

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

zone_name="$1"
current_session="$(tmux display-message -p '#S')"

if [[ -z "$zone_name" ]]; then
    # No zone specified - show available zones
    source "$SCRIPT_DIR/scripts/parse-config.sh"

    for config in "$HOME/.szpaner/zones.conf" "$HOME/.config/szpaner/zones.conf" "$SCRIPT_DIR/zones.conf"; do
        if [[ -f "$config" ]]; then
            parse_config_file "$config" 2>/dev/null
            break
        fi
    done

    if [[ ${#all_zones[@]} -gt 0 ]]; then
        tmux display-message "Available zones: ${all_zones[*]}"
    else
        tmux display-message "No zones found. Create ~/.szpaner/zones.conf"
    fi
    exit 0
fi

# Spawn the zone in current session
exec "$SCRIPT_DIR/scripts/spawn-zone.sh" "$zone_name" "$current_session"
