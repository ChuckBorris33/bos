#!/bin/bash
# Starts a Gamescope session with ES-DE frontend.

# Set up logging to a dedicated file in the steam user's home directory
exec > "/home/steam/esde_kiosk.log" 2>&1
set -x

exec gamescope -W 1920 -H 1080 -- es-de
