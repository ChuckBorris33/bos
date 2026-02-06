#!/bin/bash
set -e

# wait-for-vpn.sh - Waits for gluetun VPN to be connected
# This script runs on the HOST, not inside the container
# It enters the gluetun container's network namespace to check the VPN status

# Configuration
GLUETUN_PORT="${GLUETUN_PORT:-9090}"
MAX_RETRIES="${MAX_RETRIES:-30}"
RETRY_INTERVAL="${RETRY_INTERVAL:-2}"

# URL to check VPN status (localhost from within gluetun's network namespace)
HEALTH_URL="http://127.0.0.1:${GLUETUN_PORT}/v1/openvpn/status"

echo "Checking if gluetun VPN is connected..."

for i in $(seq 1 "$MAX_RETRIES"); do
    # Get gluetun container's PID (needed for nsenter)
    GLUETUN_PID=$(podman inspect --format '{{.State.Pid}}' gluetun 2>/dev/null || echo "")

    if [ -z "$GLUETUN_PID" ] || [ "$GLUETUN_PID" = "0" ]; then
        echo "Gluetun container not running yet. Retrying ($i/$MAX_RETRIES)..."
        sleep "$RETRY_INTERVAL"
        continue
    fi

    # Enter gluetun's network namespace and check VPN status
    # nsenter -t <pid> -n enters the network namespace of the target process
    if HEALTH_RESPONSE=$(nsenter -t "$GLUETUN_PID" -n curl -sf "$HEALTH_URL" 2>/dev/null); then
        # Check if VPN is actually connected (status: running)
        if echo "$HEALTH_RESPONSE" | grep -qi '"status":"running"'; then
            echo "Gluetun VPN is connected. Starting qBittorrent."
            exit 0
        else
            echo "Gluetun VPN not connected yet. Retrying ($i/$MAX_RETRIES)..."
            sleep "$RETRY_INTERVAL"
        fi
    else
        echo "Gluetun health endpoint not responding. Retrying ($i/$MAX_RETRIES)..."
        sleep "$RETRY_INTERVAL"
    fi
done

echo "ERROR: Timeout waiting for gluetun VPN connection after $MAX_RETRIES retries"
exit 1
