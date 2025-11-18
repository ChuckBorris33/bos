#!/usr/bin/env bash

set -euo pipefail

# Define user-specific paths
CONFIG_DIR="$HOME/.config/bootc-hooks"
VERSION_FILE="$CONFIG_DIR/version.yaml"
SWITCH_HOOKS_DIR="/usr/libexec/bootc-hooks/user/switch"
UPDATE_HOOKS_DIR="/usr/libexec/bootc-hooks/user/update"
BOOT_HOOKS_DIR="/usr/libexec/bootc-hooks/user/boot"

# Ensure the config directory exists
mkdir -p "$CONFIG_DIR"

old_image=""
old_digest=""
if [ -f "$VERSION_FILE" ]; then
    echo "Reading existing image and digest from $VERSION_FILE"
    old_image=$(yq e '.image' "$VERSION_FILE")
    old_digest=$(yq e '.digest' "$VERSION_FILE")
    echo "Existing User Image: ${old_image}"
    echo "Existing User Digest: ${old_digest}"
fi

# Get current booted image information
output=$(bootc status --format yaml --booted)
new_image=$(echo "$output" | yq e '.status.booted.image.image.image')
new_digest=$(echo "$output" | yq e '.status.booted.image.imageDigest')

# Create the YAML content
yaml_content=$(cat <<EOF
image: ${new_image}
digest: ${new_digest}
EOF
)

# Write the new version info to the user's version file
echo "$yaml_content" > "$VERSION_FILE"

# --- Run Hooks ---

# Run switch hooks if the image has changed
if [ "${new_image}" != "${old_image}" ]; then
    echo "Image has changed for user. Running switch hooks."
    if [ -d "$SWITCH_HOOKS_DIR" ]; then
        for hook in "$SWITCH_HOOKS_DIR"/*; do
            if [ -x "$hook" ]; then
                echo "Running user switch hook: $hook"
                "$hook"
            fi
        done
    fi
fi

# Run update hooks if the digest has changed
if [ "${new_digest}" != "${old_digest}" ]; then
    echo "Digest has changed for user. Running update hooks."
    if [ -d "$UPDATE_HOOKS_DIR" ]; then
        for hook in "$UPDATE_HOOKS_DIR"/*; do
            if [ -x "$hook" ]; then
                echo "Running user update hook: $hook"
                "$hook"
            fi
        done
    fi
fi

# Always run boot hooks
echo "Running user boot hooks."
if [ -d "$BOOT_HOOKS_DIR" ]; then
    for hook in "$BOOT_HOOKS_DIR"/*; do
        if [ -x "$hook" ];
        then
            echo "Running user boot hook: $hook"
            "$hook"
        fi
    done
fi

echo "User bootc hooks finished."
