# /etc/bos/media_server/config.sh
#
# This file defines the media services to be configured.
# It is sourced by the media-config-subst.service before running envsubst.
# The MEDIA_SERVER_IP variable is made available by the 90-media-server-ip
# systemd environment generator.

export CADDY_SERVICES="
# --- HTTPS site with path-based routing ---
home.ancon-mimosa.ts.net {

    # Jellyfin
    handle_path /media* {
        reverse_proxy localhost:8096
    }

    # Fsync
    handle_path /files* {
        reverse_proxy localhost:8088
    }
}

# --- HTTP redirects for old .home names ---
http://media.home, http://www.media.home {
    reverse_proxy localhost:8096
}

http://files.home, http://www.files.home {
    reverse_proxy localhost:8088
}

http://dash.home, http://www.dash.home {
    reverse_proxy localhost:8090
}
"

export DNSMASQ_DOMAINS="media.home files.home dash.home"
