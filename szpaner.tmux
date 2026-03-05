#!/usr/bin/env bash

# szPaner TPM plugin initialization

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up command alias for inside tmux: :sz zoneName
# This allows users to run :sz dev, :sz servers, etc from tmux command mode
tmux set-option -gq command-alias[100] "sz=run-shell '$CURRENT_DIR/scripts/sz-tmux.sh %%'"

# Optional: Set up a key binding (Prefix + Z) to show zone picker
# tmux bind-key Z run-shell "$CURRENT_DIR/scripts/zone-picker.sh"

# Display installation message with actual path
tmux display-message "szPaner loaded! Use :sz <zone> or add to PATH: export PATH=\"\$PATH:$CURRENT_DIR/bin\""
