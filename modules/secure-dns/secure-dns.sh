#!/usr/bin/env bash

set -euo pipefail

# Module-specific directories and paths
MODULE_DIRECTORY="${MODULE_DIRECTORY:-/tmp/modules}"
# Resolved configuration file path
RESOLVED_FILE="/etc/resolved.d/secure-dns.conf"
# Configuration values
PROVIDER=$(echo "${1}" | jq -r 'try .["provider"]')
PROVIDER_CONFIGURATION_FILE="${MODULE_DIRECTORY}"/secure-dns/configs/"${PROVIDER}".conf

if [ -f $PROVIDER_CONFIGURATION_FILE ]; then
    mkdir -p "$(dirname "$RESOLVED_FILE")"
    cp -r "$PROVIDER_CONFIGURATION_FILE" "$RESOLVED_FILE"
else
    echo "Error: Unsupported DNS provider: ${PROVIDER}"
    exit 1
fi
