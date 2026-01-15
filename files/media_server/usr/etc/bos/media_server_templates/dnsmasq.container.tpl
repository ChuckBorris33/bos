# /etc/containers/systemd/dnsmasq.container
#
# This file is auto-generated from a template by the media-config-subst.service
# using envsubst. Do not edit manually.
#
# To change configuration, edit /etc/bos/media_server/config.sh
# and reboot the system.

[Unit]
Description=Dnsmasq DNS Server
After=network-online.target
Wants=network-online.target

[Container]
Image=docker.io/dockurr/dnsmasq:latest
AutoUpdate=registry
ContainerName=dnsmasq
AddCapability=CAP_NET_BIND_SERVICE

# Publish DNS port 53 on both TCP and UDP.
PublishPort=${MEDIA_SERVER_IP}:53:53/tcp
PublishPort=${MEDIA_SERVER_IP}:53:53/udp

# Mount the configuration directory.
Volume=/opt/dnsmasq/dnsmasq.d:/etc/dnsmasq.d:z

[Service]
Restart=on-failure

[Install]
WantedBy=multi-user.target
