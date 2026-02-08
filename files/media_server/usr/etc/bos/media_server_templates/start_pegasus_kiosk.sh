#!/bin/bash
# Starts a Gamescope session with Pegasus frontend.

# This script is executed by Sway.
# Environment variables like DISPLAY and XDG_RUNTIME_DIR are expected to be set by Sway.

# Add flatpak to PATH if not already present.
# This is needed because sway may not run as a login shell.
export PATH="$PATH:/var/lib/flatpak/exports/bin:~/.local/share/flatpak/exports/bin"

# Start Pegasus in Gamescope, fullscreen, FullHD.
# -f: fullscreen
# -W 1920 -H 1080: resolution
# -e: Steam integration
# --: Separator for gamescope vs application args
exec gamescope -f -W 1920 -H 1080 -e -- flatpak run org.pegasus_frontend.Pegasus

