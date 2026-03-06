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
tmux set-option -gq command-alias[100] "sz=run-shell '$CURRENT_DIR/scripts/list-zones.sh'"

# Set up :sz-save command alias for saving zones
tmux set-option -gq command-alias[101] "sz-save=command-prompt -p 'save zone as:' 'run-shell \"$CURRENT_DIR/scripts/save-zone.sh %%\"'"

# Create config directory and copy example if needed
if [[ ! -d "$HOME/.config/szpaner" ]]; then
    mkdir -p "$HOME/.config/szpaner"
    if [[ -f "$CURRENT_DIR/zones.conf.example" ]] && [[ ! -f "$HOME/.config/szpaner/zones.conf" ]]; then
        cp "$CURRENT_DIR/zones.conf.example" "$HOME/.config/szpaner/zones.conf"
    fi
fi

# Check if PATH is set up for 'tmux <zone>' support
FIRST_TMUX=$(command -v tmux 2>/dev/null)
if [[ "$FIRST_TMUX" != "$CURRENT_DIR/bin/tmux" ]]; then
    tmux display-message "szPaner loaded! Prefix+Z (spawn) | Prefix+S (save) | :sz"
    tmux display-message "Optional: Run $CURRENT_DIR/install.sh for 'tmux <zone>' from terminal"
else
    tmux display-message "szPaner ready! Use: tmux <zone> | Prefix+Z | Prefix+S | :sz"
fi
