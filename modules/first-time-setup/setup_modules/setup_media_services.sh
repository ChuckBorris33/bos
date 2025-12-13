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

    # Get Tailscale IP
    log_and_spin "Getting Tailscale IP..." \
        bash -c 'TS_IP=$(tailscale ip -4 2>/dev/null); if [ -z "$TS_IP" ]; then echo "Error: Could not get Tailscale IP. Make sure Tailscale is connected." >&2; exit 1; fi; echo "$TS_IP"'

    local TS_IP
    TS_IP=$(tailscale ip -4 2>/dev/null)
    if [ -z "$TS_IP" ]; then
        gum style --bold --foreground "196" "Error: Could not get Tailscale IP. Make sure Tailscale is connected."
        return 1
    fi

    gum style --foreground "226" "Found Tailscale IP: $TS_IP"
    sleep 1

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

    # Template and destination paths
    local TEMPLATE_DIR="/etc/bos/media_server_templates"
    local CADDYFILE_TEMPLATE="$TEMPLATE_DIR/Caddyfile"
    local DNSMASQ_HOSTS_TEMPLATE="$TEMPLATE_DIR/hosts.conf"
    local DNSMASQ_CONTAINER_TEMPLATE="$TEMPLATE_DIR/dnsmasq.container"

    local CADDYFILE_DEST="/etc/caddy/Caddyfile"
    local DNSMASQ_HOSTS_DEST="/opt/dnsmasq/dnsmasq.d/hosts.conf"
    local SYSTEMD_DEST="/etc/containers/systemd"

    # Process and copy files
    log_and_spin "Processing configuration files..." \
        bash -c "
        mkdir -p \"\$(dirname \"$CADDYFILE_DEST\")\"
        sed \"s/100.X.Y.Z/$TS_IP/g\" \"$CADDYFILE_TEMPLATE\" > \"$CADDYFILE_DEST\"

        mkdir -p \"\$(dirname \"$DNSMASQ_HOSTS_DEST\")\"
        sed \"s/100.X.Y.Z/$TS_IP/g\" \"$DNSMASQ_HOSTS_TEMPLATE\" > \"$DNSMASQ_HOSTS_DEST\"

        mkdir -p \"$SYSTEMD_DEST\"
        sed \"s/100.X.Y.Z/$TS_IP/g\" \"$DNSMASQ_CONTAINER_TEMPLATE\" > \"$SYSTEMD_DEST/dnsmasq.container\"
        "

    # Reload and enable services
    log_and_spin "Reloading systemd and enabling media services..." \
        bash -c '
        systemctl daemon-reload
        systemctl enable --now caddy.service
        systemctl enable --now dnsmasq.service
        systemctl enable --now jellyfin.service
        '

    gum style --bold --foreground "212" "Media services setup complete!"
    sleep 2
}
