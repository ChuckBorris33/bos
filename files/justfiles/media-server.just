[group('Setup')]
setup-media-services:
    #!/usr/bin/env bash
    set -euxo pipefail

    if [ -d "/var/server_storage" ] && systemctl is-active --quiet caddy.service; then
        echo "Media services are already configured. Skipping."
        exit 0
    fi

    echo "Setting up media services..."
    echo "This will configure Jellyfin, Caddy, and other media services."

    echo "Initializing Caddy user and directories..."
    mkdir -p /opt/caddy/config /opt/caddy/data
    if ! getent group caddy >/dev/null; then groupadd --system --gid 82 caddy; fi
    if ! getent passwd caddy >/dev/null; then useradd --system --gid caddy --uid 82 --no-create-home --shell /bin/false caddy; fi
    chown -R caddy:caddy /opt/caddy

    echo "Initializing dnsmasq user and directories..."
    mkdir -p /opt/dnsmasq/dnsmasq.d
    if ! getent group dnsmasq >/dev/null; then groupadd --system --gid 99 dnsmasq; fi
    if ! getent passwd dnsmasq >/dev/null; then useradd --system --gid dnsmasq --uid 99 --no-create-home --shell /bin/false dnsmasq; fi
    chown -R dnsmasq:dnsmasq /opt/dnsmasq

    echo "Initializing Jellyfin user and directories..."
    mkdir -p /opt/jellyfin/config /opt/jellyfin/cache
    if ! getent group jellyfin >/dev/null; then groupadd --system --gid 1000 jellyfin; fi
    if ! getent passwd jellyfin >/dev/null; then useradd --system --gid jellyfin --uid 1000 --no-create-home --shell /bin/false jellyfin; fi
    chown -R jellyfin:jellyfin /opt/jellyfin
    if [ -f /etc/jellyfin/authentication.xml ]; then
        cp /etc/jellyfin/authentication.xml /opt/jellyfin/config/authentication.xml
        chown jellyfin:jellyfin /opt/jellyfin/config/authentication.xml
    fi

    echo "Initializing File Browser user and directories..."
    mkdir -p /opt/filebrowser
    touch /opt/filebrowser/database.db
    if ! getent group filebrowser >/dev/null; then groupadd --system --gid 1001 filebrowser; fi
    if ! getent passwd filebrowser >/dev/null; then useradd --system --gid filebrowser --uid 1001 --no-create-home --shell /bin/false filebrowser; fi
    chown -R filebrowser:filebrowser /opt/filebrowser

    if [ ! -d /var/server_storage ]; then
        echo "Creating Btrfs subvolume at /var/server_storage..."
        btrfs subvolume create /var/server_storage
    fi

    echo "Creating storage directories..."
    mkdir -p /var/server_storage/media /var/server_storage/games /var/server_storage/downloads

    echo "Setting permissions for storage directories..."
    # Add filebrowser user to the primary group of each service to grant access
    usermod -aG jellyfin filebrowser
    usermod -aG steam filebrowser

    # Set ownership and permissions for each service directory
    chown -R jellyfin:jellyfin /var/server_storage/media
    chmod -R u=rwX,g=rwX,o=rX /var/server_storage/media

    chown -R steam:steam /var/server_storage/games
    chmod -R u=rwX,g=rwX,o=rX /var/server_storage/games
    chmod -R u=rwX,g=rwX,o=rX /var/server_storage/downloads

    echo "Reloading systemd and enabling media services..."
    systemctl daemon-reload
    systemctl enable --now media-config-subst.service
    systemctl enable --now caddy.service
    systemctl enable --now dnsmasq.service
    systemctl enable --now jellyfin.service
    systemctl enable --now filebrowser.service

    echo "Media services setup complete!"

[group('Setup')]
setup-steam-kiosk:
    #!/usr/bin/env bash
    set -euxo pipefail

    KIOSK_USER="steam"

    if ! id "$KIOSK_USER" &>/dev/null; then
        echo "Creating user '$KIOSK_USER'..."
        useradd -m "$KIOSK_USER"
        echo "Setting empty password for '$KIOSK_USER'..."
        passwd -d "$KIOSK_USER"
    else
        echo "User '$KIOSK_USER' already exists. Skipping creation."
    fi

    autologin_conf="/etc/systemd/system/getty@.service.d/override.conf"
    if [ -f "$autologin_conf" ] && grep -q "$KIOSK_USER" "$autologin_conf"; then
        echo "Autologin already configured. Skipping."
    else
        echo "Configuring autologin for user '$KIOSK_USER'..."
        mkdir -p "$(dirname "$autologin_conf")"
        echo -e "[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin $KIOSK_USER --noclear %I \$TERM\nType=idle" > "$autologin_conf"
    fi

    KIOSK_SCRIPT="/home/$KIOSK_USER/start_steam_kiosk.sh"
    if [ -f "$KIOSK_SCRIPT" ]; then
        echo "Kiosk launch script already exists. Skipping."
    else
        echo "Creating Steam launch script..."
        mkdir -p "/home/$KIOSK_USER/"
        echo "IyEvYmluL2Jhc2gKIyBTdGFydHMgYSBHYW1lc2NvcGUgc2Vzc2lvbiB3aXRoIFN0ZWFtIGluIEJpZyBQaWN0dXJlIG1vZGUgb24gVFRZMS4KCmlmIHRlc3QgIiQodHR5KSIgIT0gIi9kZXYvdHR5MSI7IHRoZW4KICAgIGV4aXQgMApmaQoKZ2FtZXNjb3BlIC1lIC1mIC0tIC91c3IvYmluL3N0ZWFtIC1iaWdwaWN0dXJlCg==" | base64 -d > "$KIOSK_SCRIPT"
        chmod +x "$KIOSK_SCRIPT"
        chown "$KIOSK_USER:$KIOSK_USER" "$KIOSK_SCRIPT"
    fi

    PROFILE_FILE="/home/$KIOSK_USER/.bash_profile"
    if [ -f "$PROFILE_FILE" ] && grep -q "start_steam_kiosk.sh" "$PROFILE_FILE"; then
        echo "User profile already configured. Skipping."
    else
        echo "Configuring user profile for kiosk mode..."
        echo "" >> "$PROFILE_FILE"
        echo "# If running on tty1, and no X session is running, start Steam kiosk mode." >> "$PROFILE_FILE"
        echo 'if [ -z "$DISPLAY" ] && [ "	$(tty)" == "/dev/tty1" ]; then' >> "$PROFILE_FILE"
        echo "  exec $KIOSK_SCRIPT" >> "$PROFILE_FILE"
        echo "fi" >> "$PROFILE_FILE"
        chown "$KIOSK_USER:$KIOSK_USER" "$PROFILE_FILE"
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
        "clone-dotfiles" \
        "configure-git-identity" \
        "set-default-shell" \
        "setup-tailscale" \
        "setup-media-services" \
        "setup-steam-kiosk")

    for choice in $choices; do
        ujust $choice
    done
