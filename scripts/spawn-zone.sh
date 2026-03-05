#!/usr/bin/env bash

# szPaner - Spawn Zone Paner
# Creates a tmux window with predefined panes and commands

create_dev_zone() {
    local session_name="${1:-szpaner}"
    local window_name="dev-zone"

    # Create a new window or use existing session
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -n "$window_name"
    else
        tmux new-window -t "$session_name" -n "$window_name"
    fi

    local target="$session_name:$window_name"

    # Get the first pane ID
    local main_pane=$(tmux list-panes -t "$target" -F "#{pane_id}" | head -1)

    # Split vertically (left/right) - 60/40 split
    tmux split-window -t "$target" -h -p 40

    # Split the right pane horizontally (top/bottom)
    tmux split-window -t "$target" -v -p 50

    # Now we have 3 panes:
    # [0] - main (left, 60%)
    # [1] - top right (20%)
    # [2] - bottom right (20%)

    # Send commands to panes (with a small delay to ensure panes are ready)
    sleep 0.1

    # Pane 0: Main editor area
    tmux send-keys -t "$target.0" "echo 'Main pane - ready for editor'" C-m
    tmux send-keys -t "$target.0" "# Try: vim, nvim, or whatever you like" C-m

    # Pane 1: Top right - could be for server/build
    tmux send-keys -t "$target.1" "echo 'Top right - server pane'" C-m
    tmux send-keys -t "$target.1" "# Try: npm run dev, python -m http.server, etc" C-m

    # Pane 2: Bottom right - logs/monitoring
    tmux send-keys -t "$target.2" "echo 'Bottom right - logs/monitor pane'" C-m
    tmux send-keys -t "$target.2" "# Try: tail -f, htop, etc" C-m

    # Select the main pane
    tmux select-pane -t "$target.0"

    # Attach if not already in tmux
    if [ -z "$TMUX" ]; then
        tmux attach-session -t "$session_name"
    else
        tmux switch-client -t "$session_name"
    fi
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    create_dev_zone "$@"
fi
