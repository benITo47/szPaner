#!/usr/bin/env bash

# sz-tmux.sh - Handler for :sz command inside tmux
# Called via command-alias when user runs :sz zoneName

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

zone_name="$1"
current_session="$(tmux display-message -p '#S')"

# Find and parse config
source "$SCRIPT_DIR/scripts/parse-config.sh"

config_file=""
for config in "$HOME/.config/szpaner/zones.conf" "$HOME/szpaner.conf"; do
    if [[ -f "$config" ]]; then
        config_file="$config"
        parse_config_file "$config" 2>/dev/null
        break
    fi
done

if [[ -z "$config_file" ]]; then
    tmux display-message "No config found. Create ~/.config/szpaner/zones.conf"
    exit 0
fi

# If no zone specified, list available zones
if [[ -z "$zone_name" ]]; then
    if [[ ${#all_zones[@]} -gt 0 ]]; then
        tmux display-message "Available zones: ${all_zones[*]}"
    else
        tmux display-message "No zones defined in config"
    fi
    exit 0
fi

# Check if zone exists
zone_found=false
for zone in "${all_zones[@]}"; do
    if [[ "$zone" == "$zone_name" ]]; then
        zone_found=true
        break
    fi
done

if ! $zone_found; then
    tmux display-message "Zone '$zone_name' not found. Available: ${all_zones[*]}"
    exit 0
fi

# Spawn the zone in current session
exec "$SCRIPT_DIR/scripts/spawn-zone.sh" "$zone_name" "$current_session" "$config_file"
