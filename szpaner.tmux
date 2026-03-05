#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the main script
source "$CURRENT_DIR/scripts/spawn-zone.sh"

# Register the command with tmux
tmux bind-key C-z run-shell "$CURRENT_DIR/scripts/spawn-zone.sh"
