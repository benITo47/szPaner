#!/usr/bin/env bash

# szPaner TPM plugin initialization

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up key binding for spawning zones: Prefix + Z
# Prompts for zone name and spawns it
tmux bind-key Z command-prompt -p "spawn zone:" "run-shell '$CURRENT_DIR/scripts/sz-tmux.sh \"%%\"'"

# Also set up :sz as a simpler alias that just lists zones
tmux set-option -gq command-alias[100] "sz=display-message '#($CURRENT_DIR/scripts/list-zones.sh)'"

# Display installation message
tmux display-message "szPaner loaded! Use: Prefix+Z (inside) or 'tmux <zone>' (outside)"
