#!/bin/bash
# Starts a Gamescope session with Pegasus frontend.

# Set up logging to a dedicated file in the steam user's home directory
exec > "/home/steam/pegasus_kiosk.log" 2>&1
set -x

echo "--- start_pegasus_kiosk.sh started at $(date) ---"
echo "User: $(whoami)"
echo "Sway TTY: $(tty)" # This will likely be /dev/tty1 due to SDDM/Sway
echo "DISPLAY: $DISPLAY"
echo "WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
echo "PATH: $PATH"

# This script is executed by Sway.
# Environment variables like DISPLAY and XDG_RUNTIME_DIR are expected to be set by Sway.

# Ensure XDG_RUNTIME_DIR exists and has correct permissions
if [ -z "$XDG_RUNTIME_DIR" ]; then
    echo "XDG_RUNTIME_DIR is not set. Attempting to set it."
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 0700 "$XDG_RUNTIME_DIR"
    echo "Set XDG_RUNTIME_DIR to: $XDG_RUNTIME_DIR"
fi

# Add flatpak to PATH if not already present.
# This is needed because sway may not run as a login shell.
export PATH="$PATH:/var/lib/flatpak/exports/bin:~/.local/share/flatpak/exports/bin"
echo "Updated PATH: $PATH"

# Check if flatpak command is available
if ! command -v flatpak &> /dev/null
then
    echo "flatpak command could not be found. Is flatpak installed and in PATH?"
    exit 1
fi

echo "Attempting to start Pegasus in Gamescope..."
# Start Pegasus in Gamescope, fullscreen, FullHD.
# -f: fullscreen
# -W 1920 -H 1080: resolution
# -e: Steam integration
# --: Separator for gamescope vs application args
exec gamescope -f -W 1920 -H 1080 -e -- flatpak run org.pegasus_frontend.Pegasus
echo "Gamescope command executed. If you see this, Gamescope might have failed to start or exited immediately."

