#!/usr/bin/env bash

# szPaner Config Parser
# Parses .szpaner config files into bash arrays

# Global state
declare -g current_zone=""
declare -g current_pane=""
declare -g state="GLOBAL"  # GLOBAL, IN_ZONE, IN_PANE

# Data structures
declare -gA zone_panes           # zone_panes[zone_name]="pane1 pane2 pane3"
declare -gA zone_working_dir     # zone_working_dir[zone_name]="/path"
declare -gA zone_on_start        # zone_on_start[zone_name]="command"
declare -gA zone_on_detach       # zone_on_detach[zone_name]="command"
declare -gA pane_commands        # pane_commands[zone.pane.0]="first cmd", [zone.pane.1]="second cmd"
declare -gA pane_command_count   # pane_command_count[zone.pane]=2
declare -gA pane_working_dir     # pane_working_dir[zone.pane]="/path"
declare -gA pane_size            # pane_size[zone.pane]="60%"
declare -gA pane_split           # pane_split[zone.pane]="right|down"
declare -ga all_zones            # Array of zone names in order

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

# Validate zone name (prevent tmux keyword conflicts)
validate_zone_name() {
    local name="$1"
    local tmux_keywords="new attach detach ls list kill switch source show set display run send split select resize rename move swap choose find capture save load refresh clock lock suspend paste copy delete buffer unbind bind"

    # Check if zone name is a tmux keyword
    for keyword in $tmux_keywords; do
        if [[ "$name" == "$keyword" ]]; then
            echo "Error: Zone name '$name' conflicts with tmux command" >&2
            return 1
        fi
    done

    # Check if zone name contains only valid characters
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Zone name '$name' contains invalid characters (use only: a-z A-Z 0-9 _ -)" >&2
        return 1
    fi

    return 0
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

        # Validate zone name
        if ! validate_zone_name "$current_zone"; then
            return 1
        fi

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

    # Parse zone properties (when in zone but not in pane)
    if [[ "$state" == "IN_ZONE" ]]; then
        local key value

        if [[ "$line" =~ ^([a-z_]+)[[:space:]]+\"([^\"]+)\" ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
        elif [[ "$line" =~ ^([a-z_]+)[[:space:]]+([^[:space:]]+) ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
        else
            return
        fi

        case "$key" in
            working_dir)
                zone_working_dir[$current_zone]="$value"
                return
                ;;
            on_start)
                zone_on_start[$current_zone]="$value"
                return
                ;;
            on_detach)
                zone_on_detach[$current_zone]="$value"
                return
                ;;
        esac
    fi

    # Parse pane properties
    if [[ "$state" == "IN_PANE" ]]; then
        local key value

        # Match: key "value" or key value
        if [[ "$line" =~ ^([a-z_]+)[[:space:]]+\"([^\"]+)\" ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
        elif [[ "$line" =~ ^([a-z_]+)[[:space:]]+([^[:space:]]+) ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
        else
            return
        fi

        local pane_key="$current_zone.$current_pane"

        case "$key" in
            execute)
                # Support multiple execute statements - store with index
                local count=${pane_command_count[$pane_key]:-0}
                pane_commands["$pane_key.$count"]="$value"
                pane_command_count[$pane_key]=$((count + 1))
                ;;
            working_dir)
                pane_working_dir[$pane_key]="$value"
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
        [[ -n "${zone_working_dir[$zone]}" ]] && echo "  working_dir: ${zone_working_dir[$zone]}"
        [[ -n "${zone_on_start[$zone]}" ]] && echo "  on_start: ${zone_on_start[$zone]}"
        [[ -n "${zone_on_detach[$zone]}" ]] && echo "  on_detach: ${zone_on_detach[$zone]}"
        echo "  Panes: ${zone_panes[$zone]}"

        for pane in ${zone_panes[$zone]}; do
            local pane_key="$zone.$pane"
            echo "    Pane: $pane"

            # Show all execute commands
            local cmd_count=${pane_command_count[$pane_key]:-0}
            for ((i=0; i<cmd_count; i++)); do
                echo "      execute: ${pane_commands[$pane_key.$i]}"
            done

            [[ -n "${pane_working_dir[$pane_key]}" ]] && echo "      working_dir: ${pane_working_dir[$pane_key]}"
            [[ -n "${pane_size[$pane_key]}" ]] && echo "      size: ${pane_size[$pane_key]}"
            [[ -n "${pane_split[$pane_key]}" ]] && echo "      split: ${pane_split[$pane_key]}"
        done
        echo ""
    done
}

# Export functions for sourcing
export -f unquote trim parse_line parse_config_file print_config
