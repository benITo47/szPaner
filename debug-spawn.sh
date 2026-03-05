#!/usr/bin/env bash

# Debug script to see what's happening with pane creation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/parse-config.sh"

# Parse config
parse_config_file "$SCRIPT_DIR/examples/dev.conf"

zone_name="servers"
session_name="debug-test"

echo "=== Config for zone '$zone_name' ==="
panes=(${zone_panes[$zone_name]})
echo "Panes: ${panes[*]}"
echo ""

for ((i=0; i<${#panes[@]}; i++)); do
    pane="${panes[$i]}"
    pane_key="$zone_name.$pane"
    echo "Pane $i: $pane"
    echo "  Command: ${pane_command[$pane_key]}"
    echo "  Split: ${pane_split[$pane_key]}"
    echo "  Size: ${pane_size[$pane_key]}"
done

echo ""
echo "=== Creating zone in tmux ==="

# Kill session if exists
tmux kill-session -t "$session_name" 2>/dev/null

# Create session
tmux new-session -d -s "$session_name" -n "$zone_name"
echo "Created session: $session_name"

target="$session_name:$zone_name"

# Create panes with verbose output
for ((i=1; i<${#panes[@]}; i++)); do
    pane="${panes[$i]}"
    pane_key="$zone_name.$pane"
    split_dir="${pane_split[$pane_key]:-right}"
    size="${pane_size[$pane_key]}"

    split_flag="-h"
    case "$split_dir" in
        down|bottom) split_flag="-v" ;;
        right|left) split_flag="-h" ;;
    esac

    echo "Creating pane $i ($pane): split=$split_flag size=$size"

    if [[ -n "$size" ]]; then
        size_num="${size%\%}"
        tmux split-window -t "$target" $split_flag -p $size_num
    else
        tmux split-window -t "$target" $split_flag
    fi
done

echo ""
echo "=== Panes created ==="
tmux list-panes -t "$target" -F "#{pane_index}: #{pane_id} #{pane_width}x#{pane_height}"

echo ""
echo "=== Sending commands ==="
sleep 0.1

for ((i=0; i<${#panes[@]}; i++)); do
    pane="${panes[$i]}"
    pane_key="$zone_name.$pane"
    command="${pane_command[$pane_key]}"

    echo "Pane $i ($pane): sending '$command'"
    if [[ -n "$command" ]]; then
        tmux send-keys -t "$target.$i" "$command" C-m
    fi
done

echo ""
echo "=== Attach to see result ==="
echo "Run: tmux attach -t $session_name"
