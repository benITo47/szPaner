#!/usr/bin/env bash

# szPaner TPM plugin initialization

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up key binding for spawning zones: Prefix + Z
# Prompts for zone name and spawns it
tmux bind-key Z command-prompt -p "spawn zone:" "run-shell '$CURRENT_DIR/scripts/sz-tmux.sh \"%%\"'"

# Set up key binding for saving zones: Prefix + S
# Prompts for zone name and saves current window as zone
tmux bind-key S command-prompt -p "save zone as:" "run-shell '$CURRENT_DIR/scripts/save-zone.sh \"%%\"'"

# Also set up :sz as a simpler alias that just lists zones
tmux set-option -gq command-alias[100] "sz=display-message '#($CURRENT_DIR/scripts/list-zones.sh)'"

# Set up :sz-save command alias for saving zones
tmux set-option -gq command-alias[101] "sz-save=command-prompt -p 'save zone as:' 'run-shell \"$CURRENT_DIR/scripts/save-zone.sh %%\"'"

# Display installation message
tmux display-message "szPaner loaded! Prefix+Z (spawn) | Prefix+S (save) | :sz-save"
