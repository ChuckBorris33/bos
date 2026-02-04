#!/bin/bash
set -e

# Configuration
GLUETUN_HOST="${GLUETUN_HOST:-127.0.0.1}"
GLUETUN_PORT="${GLUETUN_PORT:-9090}"
MAX_RETRIES="${MAX_RETRIES:-30}"
RETRY_INTERVAL="${RETRY_INTERVAL:-2}"

# URL to check VPN status
HEALTH_URL="http://${GLUETUN_HOST}:${GLUETUN_PORT}/health"

echo "Checking if gluetun VPN is connected..."

for i in $(seq 1 "$MAX_RETRIES"); do
    # First check if gluetun health server is responding
    if curl -sf "${HEALTH_URL}" > /dev/null 2>&1; then
        # Health server responds - check if VPN is connected
        HEALTH_RESPONSE=$(curl -sf "${HEALTH_URL}" 2>/dev/null || echo "")

        if echo "$HEALTH_RESPONSE" | grep -qi "vpn.*connected\|status.*ok\|healthy"; then
            echo "Gluetun VPN is connected. Starting qBittorrent."
            exit 0
        elif echo "$HEALTH_RESPONSE" | grep -qi "vpn.*disconnected\|unhealthy"; then
            echo "Gluetun reports VPN disconnected. Retrying ($i/$MAX_RETRIES)..."
            sleep "$RETRY_INTERVAL"
        else
            # Health server responds but unclear status - treat as not ready
            echo "Gluetun health status unclear. Retrying ($i/$MAX_RETRIES)..."
            sleep "$RETRY_INTERVAL"
        fi
    else
        echo "Gluetun health server not responding. Retrying ($i/$MAX_RETRIES)..."
        sleep "$RETRY_INTERVAL"
    fi
done

echo "ERROR: Timeout waiting for gluetun VPN connection"
exit 1
