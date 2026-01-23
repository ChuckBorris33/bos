# /etc/bos/media_server/config.sh
#
# This file defines the media services to be configured.
# It is sourced by the media-config-subst.service before running envsubst.
# The MEDIA_SERVER_IP variable is made available by the 90-media-server-ip
# systemd environment generator.

export CADDY_SERVICES="
# --- HTTPS site with path-based routing ---
home.ancon-mimosa.ts.net {
    # Dashboard
    file_server {
        root /srv/www/dashboard
    }

    # Jellyfin
    handle_path /media* {
        reverse_proxy localhost:8096
    }

    # Fsync
    handle_path /files* {
        reverse_proxy localhost:8088
    }

    # fsqd
    handle_path /downloads* {
        reverse_proxy localhost:8092
    }

    # Audiobookshelf
    handle_path /audiobooks* {
        reverse_proxy localhost:13378
    }
}

# --- HTTP redirects for old .home names ---
http://media.home, http://www.media.home {
    reverse_proxy localhost:8096
}

http://files.home, http://www.files.home {
    reverse_proxy localhost:8088
}

http://downloads.home, http://www.downloads.home {
    reverse_proxy localhost:8092
}

http://audiobooks.home, http://www.audiobooks.home {
    reverse_proxy localhost:13378
}

http://dash.home, http://www.dash.home {
    reverse_proxy localhost:8090
}

http://yt-down.home, http://www.yt-down.home {
    reverse_proxy localhost:8081
}

http://home.home, http://www.home.home {
    root * /srv/www/dashboard
    file_server
}
"

export DNSMASQ_DOMAINS="media.home files.home dash.home yt-down.home home.home downloads.home audiobooks.home"
export SERVICE_PATTERNS="beszel*,dnsmasq*,filebrowser*,jellyfin*,metube*,caddy*,samba*,tailscale*,firewall*,sshd*,fsqd*,audiobookshelf*,gluetun*"
