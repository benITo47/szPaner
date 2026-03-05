#!/usr/bin/env bash

# List available zones

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/scripts/parse-config.sh"

# Find config
for config in "$HOME/.config/szpaner/zones.conf" "$HOME/szpaner.conf" "$SCRIPT_DIR/zones.conf"; do
    if [[ -f "$config" ]]; then
        parse_config_file "$config" 2>/dev/null
        break
    fi
done

if [[ ${#all_zones[@]} -eq 0 ]]; then
    echo "No zones found. Create ~/.config/szpaner/zones.conf"
else
    echo "Available zones: ${all_zones[*]} | Use: Prefix+Z"
fi
