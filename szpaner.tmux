#!/usr/bin/env bash

# szPaner TPM plugin initialization

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up key binding for spawning zones: Prefix + Z
# Prompts for zone name and spawns it
tmux bind-key Z command-prompt -p "spawn zone:" "run-shell '$CURRENT_DIR/scripts/sz-tmux.sh \"%%\"'"

# Also set up :sz as a simpler alias that just lists zones
tmux set-option -gq command-alias[100] "sz=display-message '#($CURRENT_DIR/scripts/list-zones.sh)'"

# Display installation message
# Show PATH instruction only if bin directory not in PATH
if ! echo "$PATH" | grep -q "$CURRENT_DIR/bin"; then
    tmux display-message "szPaner loaded! Prefix+Z to spawn | :sz lists | Add to PATH: export PATH=\$PATH:$CURRENT_DIR/bin"
else
    tmux display-message "szPaner loaded! Use: Prefix+Z or 'tmux <zone>'"
fi
