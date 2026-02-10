#!/bin/bash
# Starts a Gamescope session with Pegasus frontend.

# Set up logging to a dedicated file in the steam user's home directory
exec > "/home/steam/pegasus_kiosk.log" 2>&1
set -x

exec gamescope  -W 1920 -H 1080 -- flatpak run org.pegasus_frontend.Pegasus
