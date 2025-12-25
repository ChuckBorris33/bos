# /etc/bos/media_server/config.sh
#
# This file defines the media services to be configured.
# It is sourced by the media-config-subst.service before running envsubst.
# The MEDIA_SERVER_IP variable is made available by the 90-media-server-ip
# systemd environment generator.

export CADDY_SERVICES="
# --- HTTPS site with path-based routing ---
bosm.ancon-mimosa.ts.net {
    bind ${MEDIA_SERVER_IP}

    # Jellyfin
    handle_path /media* {
        reverse_proxy localhost:8096
    }

    # Fsync
    handle_path /fsync* {
        reverse_proxy localhost:8000
    }
}

# --- HTTP redirects for old .home names ---
http://media.home {
    redir https://bosm.ancon-mimosa.ts.net/media{uri}
}

http://fsync.home {
    redir https://bosm.ancon-mimosa.ts.net/fsync{uri}
}
"

export DNSMASQ_DOMAINS="media.home fsync.home"
