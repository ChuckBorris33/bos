#!/usr/bin/env bash

set -euo pipefail

echo "Running brewfile module"

# --- Configuration ---
JSON_CONFIG="$1"
BREWFILE_SOURCE_DIR="$CONFIG_DIRECTORY/brewfiles"
BREWFILE_DEST_DIR="/usr/local/etc/brewfiles"

# --- Parse Config ---
# Use jq to extract the 'include' array into a bash array
readarray -t INCLUDE_FILES < <(echo "$JSON_CONFIG" | jq -r '.include[]')
# Use jq to extract the 'validate' boolean
VALIDATE=$(echo "$JSON_CONFIG" | jq -r '.validate // false')

# --- Main Logic ---
if [ ${#INCLUDE_FILES[@]} -eq 0 ]; then
    echo "Warning: 'include' array is empty. No Brewfiles to process."
    exit 0
fi

echo "Ensuring destination directory exists: $BREWFILE_DEST_DIR"
mkdir -p "$BREWFILE_DEST_DIR"

echo "Copying Brewfiles..."
for brewfile in "${INCLUDE_FILES[@]}"; do
    source_path="$BREWFILE_SOURCE_DIR/$brewfile"
    dest_path="$BREWFILE_DEST_DIR/$brewfile"

    if [ -f "$source_path" ]; then
        echo "  - Copying '$brewfile' to '$BREWFILE_DEST_DIR'"
        cp "$source_path" "$dest_path"
    else
        echo "Error: Brewfile '$brewfile' not found in '$BREWFILE_SOURCE_DIR'." >&2
        exit 1
    fi
done

# if [ "$VALIDATE" = true ]; then
#     echo "Validating Brewfiles..."
#     if ! command -v /home/linuxbrew/.linuxbrew/bin/brew &> /dev/null; then
#         echo "Error: 'brew' command not found, but validation was requested." >&2
#         exit 1
#     fi

#     for brewfile in "${INCLUDE_FILES[@]}"; do
#         dest_path="$BREWFILE_DEST_DIR/$brewfile"
#         echo "  - Checking '$brewfile'..."
#         if ! /home/linuxbrew/.linuxbrew/bin/brew bundle check --file="$dest_path"; then
#             echo "Error: Validation failed for '$dest_path'." >&2
#             echo "You may need to run 'brew bundle install' or fix the Brewfile." >&2
#             exit 1
#         fi
#     done
#     echo "All Brewfiles validated successfully."
# fi

echo "Brewfile module finished."
