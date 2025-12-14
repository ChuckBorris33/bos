# /etc/bos/media_server/config.sh
#
# This file defines the media services to be configured.
# It is sourced by the media-config-subst.service before running envsubst.
# The MEDIA_SERVER_IP variable is made available by the 90-media-server-ip
# systemd environment generator.

export CADDY_SERVICES="
media.home {
	bind ${MEDIA_SERVER_IP}
    reverse_proxy localhost:8096
}

fsync.home {
	bind ${MEDIA_SERVER_IP}
    reverse_proxy localhost:8000
}
"

export DNSMASQ_DOMAINS="media.home fsync.home"
