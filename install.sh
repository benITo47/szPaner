#!/usr/bin/env bash

# szPaner installation - adds bin to PATH

set -e

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_PATH="$PLUGIN_DIR/bin"

# Check if already in PATH and positioned correctly
if echo "$PATH" | grep -q "$BIN_PATH"; then
    FIRST_TMUX=$(which -a tmux 2>/dev/null | head -1)
    if [[ "$FIRST_TMUX" == "$BIN_PATH/tmux" ]]; then
        echo "Already installed. Try: tmux dev"
        exit 0
    fi
fi

# Detect shell config
SHELL_CONFIG=""
if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *"bash"* ]]; then
    [[ -f "$HOME/.bashrc" ]] && SHELL_CONFIG="$HOME/.bashrc"
    [[ -f "$HOME/.bash_profile" ]] && SHELL_CONFIG="$HOME/.bash_profile"
fi

if [[ -z "$SHELL_CONFIG" ]]; then
    echo "Add manually: export PATH=\"$BIN_PATH:\$PATH\""
    exit 1
fi

# Add to shell config (prepend to PATH)
{
    echo ""
    echo "# szPaner"
    echo "export PATH=\"$BIN_PATH:\$PATH\""
} >> "$SHELL_CONFIG"

echo "Added to $SHELL_CONFIG"
echo "Reload: source $SHELL_CONFIG"
echo "Then: tmux dev"
