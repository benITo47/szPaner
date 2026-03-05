#!/usr/bin/env bash

# Test the config parser

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the parser
source "$SCRIPT_DIR/scripts/parse-config.sh"

# Parse the example config
echo "Parsing examples/dev.conf..."
echo ""

parse_config_file "$SCRIPT_DIR/examples/dev.conf"

# Print the results
print_config

echo "=== Test Complete ==="
echo ""
echo "Parsed zones: ${all_zones[@]}"
