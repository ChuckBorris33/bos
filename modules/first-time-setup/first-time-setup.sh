#!/bin/bash

set -euo pipefail

if [ ! -d "/usr/libexec/bootc-hooks" ]; then
    echo "Error: This module depends on the bootc-hooks module, but the /usr/libexec/bootc-hooks directory was not found." >&2
    exit 1
fi

CONFIG_PATH="/etc/first_time_setup/config.yaml"
MODULE_DIR="$MODULE_DIRECTORY/first-time-setup"
JSON_STRING=$1

# The script is executed by bootc-hook which runs as root
CONFIG_DIR=$(dirname "$CONFIG_PATH")
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
fi
#
# Convert JSON to YAML using yq and save to file
echo "$JSON_STRING" | yq -p json -o yaml > "$CONFIG_PATH"

# Copy the setup script to the bootc hooks directory
HOOKS_DIR="/usr/libexec/bootc-hooks/user/switch"
cp "$MODULE_DIR/setup-app.sh" "$HOOKS_DIR/first-time-setup.sh"
