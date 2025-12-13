#!/bin/bash
#
# This script configures a Fedora system at build time
# to automatically log in a user and start Steam in Big Picture mode using Gamescope.
#
# WARNING: This script will modify your system configuration.
# It is designed to be run within a build environment (e.g., container build) as root.
#

set -euo pipefail

echo "--- Starting Steam Kiosk Setup (with Gamescope) ---"

# --- 1. Enable SSH ---
echo "[1/2] Enabling SSH..."
systemctl enable sshd.service
echo "      SSH enabled."

# --- 2. Install Steam and Gamescope using dnf ---
echo "[2/2] Installing packages with dnf..."

# Enable RPMFusion non-free repository directly with dnf
echo "      Enabling RPMFusion non-free repository..."
dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install steam, gamescope, and other useful tools
dnf install -y steam gamescope wget
echo "      Package installation complete."
