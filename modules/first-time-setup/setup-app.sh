#!/bin/bash
# This script provides UI and utility functions for the first-time setup process.
# It is intended to be included by the main generated setup script.

set -Eeuo pipefail

export LOG_FILE="${HOME}/.cache/bos-first-time-setup.log"

# Only create the log file and redirect output if this is the main process
if [ -z "${_FTS_CHILD_PROCESS:-}" ]; then
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "--- Setup started at $(date) ---" > "$LOG_FILE"
    # Set environment variable to prevent child processes from redirecting output again
    export _FTS_CHILD_PROCESS=true
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

log_and_spin() {
    local title="$1"
    shift
    gum spin --spinner dot --title "$title" -- bash -c '"$@" >> "$LOG_FILE" 2>&1' -- "$@" > /dev/tty 2>&1
}

error_handler() {
    local exit_code=$?
    echo
    echo "An error occurred (exit code: ${exit_code})."
    echo "See log: ${LOG_FILE}"
    echo "Press Enter to close..."
    read -r _
}
trap error_handler ERR

# Part 1: Relaunch in Alacritty if needed
# -----------------------------------------------------------------------------
# If not running inside the special alacritty session, and alacritty is available, relaunch into it.
if [ -z "${IS_IN_ALACRITTY:-}" ] && command -v alacritty &> /dev/null; then
    export IS_IN_ALACRITTY=true
    # Get the absolute path of the script to handle relative paths
    SCRIPT_PATH=$(readlink -f "$0")
    alacritty --class Guake -e "$SCRIPT_PATH"
    exit 0
fi

# Part 2: Main script logic
# -----------------------------------------------------------------------------

export CONFIG_FILE="/etc/first_time_setup/config.yaml"

# Ensure brew is in PATH
if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# --- UI Functions ---

print_art() {
    local cols lines inner_height border_line
    cols=$(tput cols 2>/dev/null || echo 80)
    lines=$(tput lines 2>/dev/null || echo 24)
    # Inner vertical space between the two '=' border lines
    inner_height=$((lines - 5))
    ((inner_height < 1)) && inner_height=1

    # Build a full-width '=' border line
    border_line=$(printf '%*s' "$cols" '' | tr ' ' '=')

    # ASCII art content lines (logo + text)
    local -a art=(
"██████╗  ██████╗  ██████╗"
"██╔══██╗██╔═══██╗██╔════╝"
"██████╔╝██║   ██║╚█████╗ "
"██╔══██╗██║   ██║ ╚═══██╗"
"██████╔╝╚██████╔╝██████╔╝"
"╚═════╝  ╚═════╝ ╚═════╝ "
""
"Boris's OS"
"First time boot script"
    )

    local art_lines=${#art[@]}
    local display_art_lines=$art_lines

    # If terminal height too small, truncate art
    if (( inner_height < art_lines )); then
        display_art_lines=$inner_height
    fi

    local blank_lines=$((inner_height - display_art_lines))
    ((blank_lines < 0)) && blank_lines=0
    local top_pad=$((blank_lines / 2))
    local bottom_pad=$((blank_lines - top_pad))

    echo "$border_line"

    # Top padding
    for ((i=0; i<top_pad; i++)); do echo ""; done

    # Art (possibly truncated)
    for ((i=0; i<display_art_lines; i++)); do
        raw="${art[i]}"
        if [ -z "$raw" ]; then
            echo ""
        else
            trimmed="$(printf '%s' "$raw" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            line_len=${#trimmed}
            if (( line_len > cols )); then
                trimmed="${trimmed:0:cols}"
                line_len=${#trimmed}
            fi
            pad=$(( (cols - line_len) / 2 ))
            ((pad < 0)) && pad=0
            printf "%*s%s\n" "$pad" "" "$trimmed"
        fi
    done

    # Bottom padding
    for ((i=0; i<bottom_pad; i++)); do echo ""; done

    echo "$border_line"
}

draw_screen() {
    clear
    print_art
    # Position cursor three lines from bottom for subsequent interactive output
    local total_lines
    total_lines=$(tput lines 2>/dev/null || echo 24)
    tput cup $((total_lines - 3)) 0 2>/dev/null || true
}

clear_info() {
    local total_lines
    total_lines=$(tput lines 2>/dev/null || echo 24)
    tput cup $((total_lines - 3)) 0 2>/dev/null || true
    tput ed
    tput cup $((total_lines - 3)) 0 2>/dev/null || true
}
