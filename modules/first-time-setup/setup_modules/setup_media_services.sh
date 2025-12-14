# Module: setup_media_services
MODULE_DEPS="tailscale btrfs"

setup_media_services() {
    # Check if media services are already configured
    if [ -d "/var/server_storage" ] && systemctl is-active --quiet caddy.service; then
        gum style --bold --foreground "212" "Media services are already configured. Skipping."
        sleep 1
        return
    fi

    gum style --bold --padding "1 2" --border normal --border-foreground "212" \
        "Media Services Setup" \
        "This will configure Jellyfin, Caddy, and other media services."

    log_and_spin "Initializing Caddy user and directories..." \
        bash -c '
        mkdir -p /opt/caddy/config /opt/caddy/data
        if ! getent group caddy >/dev/null; then groupadd --system --gid 82 caddy; fi
        if ! getent passwd caddy >/dev/null; then useradd --system --gid caddy --uid 82 --no-create-home --shell /bin/false caddy; fi
        chown -R caddy:caddy /opt/caddy
    '

    log_and_spin "Initializing dnsmasq user and directories..." \
        bash -c '
        mkdir -p /opt/dnsmasq/dnsmasq.d
        if ! getent group dnsmasq >/dev/null; then groupadd --system --gid 99 dnsmasq; fi
        if ! getent passwd dnsmasq >/dev/null; then useradd --system --gid dnsmasq --uid 99 --no-create-home --shell /bin/false dnsmasq; fi
        chown -R dnsmasq:dnsmasq /opt/dnsmasq
    '

    log_and_spin "Initializing Jellyfin user and directories..." \
        bash -c '
        mkdir -p /opt/jellyfin/config /opt/jellyfin/cache
        if ! getent group jellyfin >/dev/null; then groupadd --system --gid 1000 jellyfin; fi
        if ! getent passwd jellyfin >/dev/null; then useradd --system --gid jellyfin --uid 1000 --no-create-home --shell /bin/false jellyfin; fi
        chown -R jellyfin:jellyfin /opt/jellyfin
        if [ -f /etc/jellyfin/authentication.xml ]; then
            cp /etc/jellyfin/authentication.xml /opt/jellyfin/config/authentication.xml
            chown jellyfin:jellyfin /opt/jellyfin/config/authentication.xml
        fi
    '

    log_and_spin "Initializing File Browser user and directories..." \
        bash -c '
        mkdir -p /opt/filebrowser
        touch /opt/filebrowser/database.db
        if ! getent group filebrowser >/dev/null; then groupadd --system --gid 1001 filebrowser; fi
        if ! getent passwd filebrowser >/dev/null; then useradd --system --gid filebrowser --uid 1001 --no-create-home --shell /bin/false filebrowser; fi
        chown -R filebrowser:filebrowser /opt/filebrowser
    '

    # Create storage
    if [ ! -d /var/server_storage ]; then
        log_and_spin "Creating Btrfs subvolume at /var/server_storage..." \
            btrfs subvolume create /var/server_storage
    fi

    log_and_spin "Creating storage directories..." \
        bash -c 'mkdir -p /var/server_storage/media /var/server_storage/games /var/server_storage/downloads'

    log_and_spin "Setting permissions for storage directories..." \
        bash -c '
        # Add filebrowser user to the primary group of each service to grant access
        usermod -aG jellyfin filebrowser
        usermod -aG steam filebrowser

        # Set ownership and permissions for each service directory
        chown -R jellyfin:jellyfin /var/server_storage/media
        chmod -R u=rwX,g=rwX,o=rX /var/server_storage/media

        chown -R steam:steam /var/server_storage/games
        chmod -R u=rwX,g=rwX,o=rX /var/server_storage/games
        chmod -R u=rwX,g=rwX,o=rX /var/server_storage/downloads
        '

    # Reload and enable services
    log_and_spin "Reloading systemd and enabling media services..." \
        bash -c '
        systemctl daemon-reload
        # The subst service will run once and generate all necessary configs.
        # The other services will be started after it has completed.
        systemctl enable --now media-config-subst.service
        systemctl enable --now caddy.service
        systemctl enable --now dnsmasq.service
        systemctl enable --now jellyfin.service
        systemctl enable --now filebrowser.service
        '

    gum style --bold --foreground "212" "Media services setup complete!"
    sleep 2
}
