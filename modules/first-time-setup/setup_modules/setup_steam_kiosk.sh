# Module: setup_steam_kiosk
# Sets up a 'steam' user for an automatic kiosk session with Steam in Big Picture mode.

setup_steam_kiosk() {
    local KIOSK_USER="steam"

    # --- Create Kiosk User ---
    if ! id "$KIOSK_USER" &>/dev/null; then
        log_and_spin "Creating user '$KIOSK_USER'..." \
            useradd -m "$KIOSK_USER"
        log_and_spin "Setting empty password for '$KIOSK_USER'..." \
            passwd -d "$KIOSK_USER"
    else
        gum style --foreground "226" -- "User '$KIOSK_USER' already exists. Skipping creation."
        sleep 1
        clear_info
    fi

    # --- Configure Autologin ---
    local autologin_conf="/etc/systemd/system/getty@.service.d/override.conf"
    if [ -f "$autologin_conf" ] && grep -q "$KIOSK_USER" "$autologin_conf"; then
        gum style --foreground "226" -- "Autologin already configured. Skipping."
        sleep 1
        clear_info
    else
        log_and_spin "Configuring autologin for user '$KIOSK_USER'..." \
            bash -c "mkdir -p $(dirname "$autologin_conf") && echo -e '[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin $KIOSK_USER --noclear %I \$TERM\nType=idle' > $autologin_conf"
    fi


    # --- Create Steam Kiosk Launch Script ---
    local KIOSK_SCRIPT="/home/$KIOSK_USER/start_steam_kiosk.sh"
    if [ -f "$KIOSK_SCRIPT" ]; then
        gum style --foreground "226" -- "Kiosk launch script already exists. Skipping."
        sleep 1
        clear_info
    else
        log_and_spin "Creating Steam launch script..." \
            bash -c "mkdir -p /home/$KIOSK_USER/ && \
cat <<'EOSH' > \"$KIOSK_SCRIPT\"
#!/bin/bash
# Starts a Gamescope session with Steam in Big Picture mode on TTY1.

if [ \\\"\$(tty)\\\" != \\\"/dev/tty1\\\" ]; then
    exit 0
fi

gamescope -e -f -- /usr/bin/steam -bigpicture
EOSH
chmod +x \"$KIOSK_SCRIPT\" && \
chown $KIOSK_USER:$KIOSK_USER \"$KIOSK_SCRIPT\"
"
    fi

    # --- Configure User's Profile ---
    local PROFILE_FILE="/home/$KIOSK_USER/.bash_profile"
    if [ -f "$PROFILE_FILE" ] && grep -q "start_steam_kiosk.sh" "$PROFILE_FILE"; then
        gum style --foreground "226" -- "User profile already configured. Skipping."
        sleep 1
        clear_info
    else
        log_and_spin "Configuring user profile for kiosk mode..." \
            bash -c "
cat <<EOF >> \"$PROFILE_FILE\"

# If running on tty1, and no X session is running, start Steam kiosk mode.
if [ -z \\\"\\\$DISPLAY\\\" ] && [ \\\"\$(tty)\\\" == \\\"/dev/tty1\\\" ]; then
  exec $KIOSK_SCRIPT
fi
EOF
chown $KIOSK_USER:$KIOSK_USER \"$PROFILE_FILE\"
"
    fi

    clear_info
    gum style --bold --foreground "212" "Steam Kiosk setup complete!"
    sleep 2
}
