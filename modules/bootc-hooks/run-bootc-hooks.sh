#!/usr/bin/env bash

set -euo pipefail

VERSION_FILE="/var/lib/bootc-hooks/version.yaml"
SWITCH_HOOKS_DIR="/usr/libexec/bootc-hooks/switch.d"
UPDATE_HOOKS_DIR="/usr/libexec/bootc-hooks/update.d"
BOOT_HOOKS_DIR="/usr/libexec/bootc-hooks/boot.d"

old_image=""
old_digest=""
if [ -f "$VERSION_FILE" ]; then
    echo "Reading existing image and digest from $VERSION_FILE"
    old_image=$(yq e '.image' "$VERSION_FILE")
    old_digest=$(yq e '.digest' "$VERSION_FILE")
    echo "Existing Image: ${old_image}"
    echo "Existing Digest: ${old_digest}"
fi

output=$(bootc status --format yaml --booted)

new_image=$(echo "$output" | yq e '.status.booted.image.image.image')
new_digest=$(echo "$output" | yq e '.status.booted.image.imageDigest')

# Create the directory if it doesn't exist
sudo mkdir -p /var/lib/bootc-hooks

# Create the YAML content
yaml_content=$(cat <<EOF
image: ${new_image}
digest: ${new_digest}
EOF
)

# Write the YAML content to the file
echo "$yaml_content" | sudo tee "$VERSION_FILE" > /dev/null

if [ "${new_image}" != "${old_image}" ]; then
    echo "Image has changed. Running switch hooks."
    if [ -f /usr/libexec/bootc-hooks/switch.sh ]; then
        echo "Running main switch hook."
        /usr/libexec/bootc-hooks/switch.sh
    fi
    if [ -d "$SWITCH_HOOKS_DIR" ]; then
        for hook in "$SWITCH_HOOKS_DIR"/*; do
            if [ -x "$hook" ]; then
                echo "Running hook: $hook"
                "$hook"
            fi
        done
    fi
fi

if [ "${new_digest}" != "${old_digest}" ]; then
    echo "Digest has changed. Running update hooks."
    if [ -f /usr/libexec/bootc-hooks/update.sh ]; then
        echo "Running main update hook."
        /usr/libexec/bootc-hooks/update.sh
    fi
    if [ -d "$UPDATE_HOOKS_DIR" ]; then
        for hook in "$UPDATE_HOOKS_DIR"/*; do
            if [ -x "$hook" ]; then
                echo "Running hook: $hook"
                "$hook"
            fi
        done
    fi
fi

echo "Running boot hooks."
if [ -f /usr/libexec/bootc-hooks/boot.sh ]; then
    echo "Running main boot hook."
    /usr/libexec/bootc-hooks/boot.sh
fi
if [ -d "$BOOT_HOOKS_DIR" ]; then
    for hook in "$BOOT_HOOKS_DIR"/*; do
        if [ -x "$hook" ]; then
            echo "Running hook: $hook"
            "$hook"
        fi
    done
fi
