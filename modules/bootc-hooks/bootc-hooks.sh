#!/bin/bash
echo "Running bootc-hooks module"

set -euo pipefail

# Define paths
SCRIPT_NAME="run-bootc-hooks.sh"
SOURCE_SCRIPT="$MODULE_DIRECTORY/bootc-hooks/$SCRIPT_NAME"
TARGET_SCRIPT="/usr/libexec/bootc-hooks/$SCRIPT_NAME"
SERVICE_NAME="bootc-hooks.service"
SERVICE_FILE="/usr/lib/systemd/system/$SERVICE_NAME"

# Copy the script to /usr/libexec
install -Dm 0755 "$SOURCE_SCRIPT" "$TARGET_SCRIPT"

# Create the systemd service file
cat <<EOF >"$SERVICE_FILE"
[Unit]
Description=Run bootc hooks after boot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=$TARGET_SCRIPT

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl -f enable $SERVICE_NAME

BOOTC_HOOKS_DIR="${CONFIG_DIRECTORY}/bootc-hooks"
mkdir -p /usr/libexec/bootc-hooks
cp -rf "$BOOTC_HOOKS_DIR"/* /usr/libexec/bootc-hooks
chmod -R +x /usr/libexec/bootc-hooks

# Install dependencies
dnf -y install yq
