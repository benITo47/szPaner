#!/usr/bin/env bash

# List available zones

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/scripts/parse-config.sh"

# Find config
for config in "$HOME/.szpaner/zones.conf" "$HOME/.config/szpaner/zones.conf" "$SCRIPT_DIR/zones.conf" "$SCRIPT_DIR/examples/dev.conf"; do
    if [[ -f "$config" ]]; then
        parse_config_file "$config" 2>/dev/null
        break
    fi
done

if [[ ${#all_zones[@]} -eq 0 ]]; then
    echo "No zones found. Create ~/.szpaner/zones.conf"
else
    echo "Available zones: ${all_zones[*]} | Use: Prefix+Z"
fi
