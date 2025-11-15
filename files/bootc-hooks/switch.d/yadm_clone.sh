#!/usr/bin/env bash

set -euo pipefail

# Detect the primary user (usually UID 1000)
USER=$(getent passwd 1000 | cut -d: -f1)

if [ -z "$USER" ]; then
    echo "Primary user not found, exiting."
    exit 0
fi

runuser -l "$USER" -c "yadm clone --no-bootstrap git@github.com:ChuckBorris33/dotfiles.git && yadm reset --hard origin/main"
