#!/usr/bin/env bash

# Quick demo script to test szPaner
# Run this to see the plugin in action

echo "🚀 szPaner Demo"
echo "==============="
echo ""
echo "Available zones in examples/dev.conf:"
echo "  - dev      (3 panes: editor, server, logs)"
echo "  - servers  (3 panes: prod SSH, staging SSH, htop)"
echo ""
echo "Spawning 'dev' zone..."
echo ""

./scripts/spawn-zone.sh dev demo-session
