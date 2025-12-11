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

# --- Configuration ---
KIOSK_USER="steam"

# --- 1. Enable SSH ---
echo "[1/7] Enabling SSH..."
systemctl enable sshd.service
echo "      SSH enabled."

# --- 2. Create Kiosk User ---
echo "[2/7] Creating user '$KIOSK_USER'..."
if ! id "$KIOSK_USER" &>/dev/null; then
    useradd -m "$KIOSK_USER"
    # Set an empty password. This user will autologin.
    passwd -d "$KIOSK_USER"
    echo "      User '$KIOSK_USER' created."
else
    echo "      User '$KIOSK_USER' already exists."
fi

# --- 3. Configure Autologin ---
echo "[3/7] Configuring autologin for user '$KIOSK_USER' on TTY1..."
mkdir -p /etc/systemd/system/getty@.service.d
cat <<EOF > /etc/systemd/system/getty@.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $KIOSK_USER --noclear %I \$TERM
Type=idle
EOF
echo "      Autologin configured."

# --- 4. Install Steam and Gamescope using dnf ---
echo "[4/7] Installing packages with dnf..."

# Enable RPMFusion non-free repository directly with dnf
echo "      Enabling RPMFusion non-free repository..."
dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install steam, gamescope, and other useful tools
dnf install -y steam gamescope wget
echo "      Package installation complete."

# --- 5. Create Steam Kiosk Launch Script ---
echo "[5/7] Creating Steam launch script for Gamescope..."
mkdir -p /home/$KIOSK_USER/
cat <<'EOF' > /home/$KIOSK_USER/start_steam_kiosk.sh
#!/bin/bash
#
# This script starts a Gamescope session with Steam in Big Picture mode.
# It's intended to be executed upon login on TTY1.

# Ensure we are on the correct virtual terminal
if [ "$(tty)" != "/dev/tty1" ]; then
    echo "Not on TTY1. Exiting."
    exit 0
fi

echo "Starting Gamescope session with Steam..."

# Launch Steam in Big Picture mode within Gamescope.
# -e: Enables Steam integration (for controller focus, etc.)
# -f: Fullscreen mode
# --: Separates gamescope arguments from the command to be run
gamescope -e -f -- /usr/bin/steam -bigpicture
EOF
chmod +x /home/$KIOSK_USER/start_steam_kiosk.sh
chown $KIOSK_USER:$KIOSK_USER /home/$KIOSK_USER/start_steam_kiosk.sh
echo "      Steam launch script created at /home/$KIOSK_USER/start_steam_kiosk.sh"

# --- 6. Configure User's Profile to Launch Kiosk ---
echo "[6/7] Configuring user's .bash_profile to launch the kiosk script..."
cat <<EOF >> /home/$KIOSK_USER/.bash_profile
# If running on tty1, and no X session is running, start Steam kiosk mode.
if [ -z "\$DISPLAY" ] && [ "\$(tty)" == "/dev/tty1" ]; then
  # Use 'exec' to replace the shell process with the script
  exec /home/$KIOSK_USER/start_steam_kiosk.sh
fi
EOF
chown $KIOSK_USER:$KIOSK_USER /home/$KIOSK_USER/.bash_profile
echo "      User profile configured."

# --- 7. Final Instructions ---
echo "[7/7] Setup Complete!"
echo ""
echo "------------------------------------------------------------------"
echo "Build-time setup is complete. The system is now configured to"
echo "autologin as '$KIOSK_USER' and start Steam via Gamescope on the first TTY."
echo "------------------------------------------------------------------"
