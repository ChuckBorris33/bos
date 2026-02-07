#!/bin/bash
# Starts a Gamescope session with Pegasus frontend on TTY1.

if test "$(tty)" != "/dev/tty1"; then
    exit 0
fi

# Export required environment variables for Gamescope and Pegasus
export DISPLAY=:0
export XDG_RUNTIME_DIR=/run/user/$(id - u)

# Ensure runtime directory exists
mkdir -p "$XDG_RUNTIME_DIR"

# Add flatpak to PATH if not already present
export PATH="$PATH:/var/lib/flatpak/exports/bin:~/.local/share/flatpak/exports/bin"

# Start Pegasus in Gamescope
# -e: Enable steam integration
# --: Separator for gamescope vs application args
exec gamescope -e -- flatpak run org.pegasus_frontend.Pegasus
