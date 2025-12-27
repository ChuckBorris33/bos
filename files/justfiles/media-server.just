[group('Setup')]
setup-media-services:
    #!/usr/bin/env bash
    set -euxo pipefail

    echo "Setting up media services..."
    echo "This will configure Jellyfin, Caddy, and other media services."

    echo "Initializing Caddy user and directories..."
    sudo mkdir -p /var/opt/caddy/config /var/opt/caddy/data
    if ! getent group caddy >/dev/null; then sudo groupadd --system --gid 82 caddy; fi
    if ! getent passwd caddy >/dev/null; then sudo useradd --system --gid caddy --uid 82 --no-create-home --shell /bin/false caddy; fi
    sudo chown -R caddy:caddy /var/opt/caddy

    echo "Initializing dnsmasq user and directories..."
    sudo mkdir -p /var/opt/dnsmasq/dnsmasq.d
    sudo touch /var/opt/dnsmasq/dnsmasq.custom
    if ! getent group dnsmasq >/dev/null; then sudo groupadd --system --gid 99 dnsmasq; fi
    if ! getent passwd dnsmasq >/dev/null; then sudo useradd --system --gid dnsmasq --uid 99 --no-create-home --shell /bin/false dnsmasq; fi
    sudo chown -R dnsmasq:dnsmasq /var/opt/dnsmasq

    echo "Initializing Jellyfin user and directories..."
    sudo mkdir -p /var/opt/jellyfin/config /var/opt/jellyfin/cache
    if ! getent group jellyfin >/dev/null; then sudo groupadd --system --gid 1002 jellyfin; fi
    if ! getent passwd jellyfin >/dev/null; then sudo useradd --system --gid jellyfin --uid 1002 --yes-create-home --shell /bin/false jellyfin; fi
    sudo chown -R jellyfin:jellyfin /var/opt/jellyfin
    if [ -f /etc/jellyfin/authentication.xml ]; then
        sudo cp /etc/jellyfin/authentication.xml /var/opt/jellyfin/config/authentication.xml
        sudo chown jellyfin:jellyfin /var/opt/jellyfin/config/authentication.xml
    fi

    echo "Initializing File Browser user and directories..."
    sudo mkdir -p /var/opt/filebrowser
    sudo mkdir -p /var/opt/filebrowser/config
    sudo mkdir -p /var/opt/filebrowser/database
    if ! getent group filebrowser >/dev/null; then sudo groupadd --system --gid 1001 filebrowser; fi
    if ! getent passwd filebrowser >/dev/null; then sudo useradd --system --gid filebrowser --uid 1001 --no-create-home --shell /bin/false filebrowser; fi
    sudo chown -R filebrowser:filebrowser /var/opt/filebrowser

    echo "Initializing Beszel directories..."
    sudo mkdir -p /var/opt/beszel/data

    if [ ! -d /var/server_storage ]; then
        echo "Creating Btrfs subvolume at /var/server_storage..."
        sudo btrfs subvolume create /var/server_storage
    fi

    echo "Creating storage directories..."
    sudo mkdir -p /var/server_storage/media /var/server_storage/games /var/server_storage/downloads

    echo "Initializing serverstorage group..."
    if ! getent group serverstorage >/dev/null; then sudo groupadd --system --gid 1003 serverstorage; fi

    echo "Adding users to serverstorage group..."
    sudo usermod -aG serverstorage jellyfin
    sudo usermod -aG serverstorage filebrowser

    echo "Setting permissions for storage directories..."
    sudo chown -R filebrowser:serverstorage /var/server_storage
    sudo chmod -R u=rwX,g=rwsX,o-rwx /var/server_storage

    echo "Reloading systemd and restarting media services..."
    sudo systemctl start media-config-subst.service
    sudo systemctl daemon-reload
    sudo systemctl restart caddy.service || true
    sudo systemctl restart jellyfin.service || true
    sudo systemctl restart filebrowser.service || true
    sudo systemctl restart beszel.service || true
    echo "Media services setup complete!"

[group('Setup')]
setup-steam-kiosk:
    #!/usr/bin/env bash
    set -euxo pipefail

    KIOSK_USER="steam"

    if ! id "$KIOSK_USER" &>/dev/null; then
        echo "Creating user '$KIOSK_USER'..."
        sudo useradd -m "$KIOSK_USER"
        echo "Setting empty password for '$KIOSK_USER'..."
        sudo passwd -d "$KIOSK_USER"
    else
        echo "User '$KIOSK_USER' already exists. Skipping creation."
    fi

    autologin_conf="/etc/systemd/system/getty@.service.d/override.conf"
    if [ -f "$autologin_conf" ] && grep -q "$KIOSK_USER" "$autologin_conf"; then
        echo "Autologin already configured. Skipping."
    else
        echo "Configuring autologin for user '$KIOSK_USER'..."
        sudo mkdir -p "$(dirname "$autologin_conf")"
        echo -e "[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin $KIOSK_USER --noclear %I \$TERM\nType=idle" | sudo tee "$autologin_conf" > /dev/null
    fi

    KIOSK_SCRIPT="/home/$KIOSK_USER/start_steam_kiosk.sh"
    if [ -f "$KIOSK_SCRIPT" ]; then
        echo "Kiosk launch script already exists. Skipping."
    else
        echo "Creating Steam launch script..."
        sudo mkdir -p "/home/$KIOSK_USER/"
        echo "IyEvYmluL2Jhc2gKIyBTdGFydHMgYSBHYW1lc2NvcGUgc2Vzc2lvbiB3aXRoIFN0ZWFtIGluIEJpZyBQaWN0dXJlIG1vZGUgb24gVFRZMS4KCmlmIHRlc3QgIiQodHR5KSIgIT0gIi9kZXYvdHR5MSI7IHRoZW4KICAgIGV4aXQgMApmaQoKZ2FtZXNjb3BlIC1lIC1mIC0tIC91c3IvYmluL3N0ZWFtIC1iaWdwaWN0dXJlCg==" | sudo base64 -d > "$KIOSK_SCRIPT"
        sudo chmod +x "$KIOSK_SCRIPT"
        sudo chown "$KIOSK_USER:$KIOSK_USER" "$KIOSK_SCRIPT"
    fi

    PROFILE_FILE="/home/$KIOSK_USER/.bash_profile"
    if [ -f "$PROFILE_FILE" ] && grep -q "start_steam_kiosk.sh" "$PROFILE_FILE"; then
        echo "User profile already configured. Skipping."
    else
        echo "Configuring user profile for kiosk mode..."
        echo "" | sudo tee -a "$PROFILE_FILE" > /dev/null
        echo "# If running on tty1, and no X session is running, start Steam kiosk mode." | sudo tee -a "$PROFILE_FILE" > /dev/null
        echo 'if [ -z "$DISPLAY" ] && [ "	$(tty)" == "/dev/tty1" ]; then' | sudo tee -a "$PROFILE_FILE" > /dev/null
        echo "  exec $KIOSK_SCRIPT" | sudo tee -a "$PROFILE_FILE" > /dev/null
        echo "fi" | sudo tee -a "$PROFILE_FILE" > /dev/null
        sudo chown "$KIOSK_USER:$KIOSK_USER" "$PROFILE_FILE"
    fi

    echo "Steam Kiosk setup complete!"

[group('Setup')]
setup-all:
    @ujust install-default-brew
    @ujust install-default-flatpaks
    @ujust clone-dotfiles
    @ujust configure-git-identity
    @ujust set-default-shell
    @ujust setup-tailscale
    @ujust setup-media-services
    @ujust setup-steam-kiosk

[group('Setup')]
setup-interactive:
    #!/usr/bin/env bash
    set -euxo pipefail

    choices=$(gum choose --no-limit \
        "install-default-brew" \
        "install-default-flatpaks" \
        "login-gh" \
        "clone-dotfiles" \
        "configure-git-identity" \
        "set-default-shell" \
        "setup-tailscale" \
        "setup-media-services" \
        "setup-steam-kiosk")

    for choice in $choices; do
        ujust $choice
    done

[group('Debug')]
debug-quadlet:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo /usr/lib/systemd/system-generators/podman-system-generator --dryrun
