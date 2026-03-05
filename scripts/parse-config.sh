#!/usr/bin/env bash

# szPaner Config Parser
# Parses .szpaner config files into bash arrays

# Global state
declare -g current_zone=""
declare -g current_pane=""
declare -g state="GLOBAL"  # GLOBAL, IN_ZONE, IN_PANE

# Data structures
declare -gA zone_panes      # zone_panes[zone_name]="pane1 pane2 pane3"
declare -gA pane_command    # pane_command[zone.pane]="command" (any command, including ssh)
declare -gA pane_size       # pane_size[zone.pane]="60%"
declare -gA pane_split      # pane_split[zone.pane]="right|down"
declare -ga all_zones       # Array of zone names in order

# Remove quotes from a string
unquote() {
    local str="$1"
    # Remove leading/trailing quotes
    str="${str#\"}"
    str="${str%\"}"
    echo "$str"
}

# Trim whitespace
trim() {
    local str="$1"
    # Remove leading whitespace
    str="${str#"${str%%[![:space:]]*}"}"
    # Remove trailing whitespace
    str="${str%"${str##*[![:space:]]}"}"
    echo "$str"
}

# Parse a single line
parse_line() {
    local line="$1"

    # Trim whitespace
    line=$(trim "$line")

    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && return

    # Check for zone declaration
    if [[ "$line" =~ ^zone[[:space:]]+\"([^\"]+)\"[[:space:]]*\{? ]]; then
        current_zone="${BASH_REMATCH[1]}"
        state="IN_ZONE"
        all_zones+=("$current_zone")
        zone_panes[$current_zone]=""
        return
    fi

    # Check for pane declaration
    if [[ "$line" =~ ^pane[[:space:]]+\"([^\"]+)\"[[:space:]]*\{? ]]; then
        if [[ "$state" != "IN_ZONE" ]]; then
            echo "Error: pane outside of zone" >&2
            return 1
        fi
        current_pane="${BASH_REMATCH[1]}"
        state="IN_PANE"

        # Add pane to zone's pane list
        if [[ -z "${zone_panes[$current_zone]}" ]]; then
            zone_panes[$current_zone]="$current_pane"
        else
            zone_panes[$current_zone]+=" $current_pane"
        fi
        return
    fi

    # Check for closing brace
    if [[ "$line" =~ ^\} ]]; then
        if [[ "$state" == "IN_PANE" ]]; then
            state="IN_ZONE"
            current_pane=""
        elif [[ "$state" == "IN_ZONE" ]]; then
            state="GLOBAL"
            current_zone=""
        fi
        return
    fi

    # Parse pane properties
    if [[ "$state" == "IN_PANE" ]]; then
        local key value

        # Match: key "value" or key value
        if [[ "$line" =~ ^([a-z]+)[[:space:]]+\"([^\"]+)\" ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
        elif [[ "$line" =~ ^([a-z]+)[[:space:]]+([^[:space:]]+) ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
        else
            return
        fi

        local pane_key="$current_zone.$current_pane"

        case "$key" in
            command)
                pane_command[$pane_key]="$value"
                ;;
            size)
                pane_size[$pane_key]="$value"
                ;;
            split)
                pane_split[$pane_key]="$value"
                ;;
            *)
                echo "Warning: unknown property '$key'" >&2
                ;;
        esac
    fi
}

# Parse a config file
parse_config_file() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        echo "Error: config file not found: $config_file" >&2
        return 1
    fi

    while IFS= read -r line; do
        parse_line "$line"
    done < "$config_file"
}

# Debug: print parsed config
print_config() {
    echo "=== Parsed Configuration ==="
    echo ""

    for zone in "${all_zones[@]}"; do
        echo "Zone: $zone"
        echo "  Panes: ${zone_panes[$zone]}"

        for pane in ${zone_panes[$zone]}; do
            local pane_key="$zone.$pane"
            echo "    Pane: $pane"
            [[ -n "${pane_command[$pane_key]}" ]] && echo "      command: ${pane_command[$pane_key]}"
            [[ -n "${pane_size[$pane_key]}" ]] && echo "      size: ${pane_size[$pane_key]}"
            [[ -n "${pane_split[$pane_key]}" ]] && echo "      split: ${pane_split[$pane_key]}"
        done
        echo ""
    done
}

# Export functions for sourcing
export -f unquote trim parse_line parse_config_file print_config
