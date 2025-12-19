[group('Setup')]
copy-cosmic-config:
    #!/usr/bin/env bash
    echo "Copying COSMIC config..."
    source_dir="/usr/share/cosmic"
    dest_dir="$HOME/.config/cosmic"

    if [ -d "$source_dir" ]; then
        mkdir -p "$dest_dir"
        echo "Copying COSMIC files..."
        cp -rfT "$source_dir" "$dest_dir"
        cp -rfT "$source_dir" "$dest_dir"
    else
        echo "Warning: $source_dir not found. Skipping COSMIC config copy."
    fi

[group('Setup')]
setup-all:
    @ujust install-default-brew
    @ujust install-default-flatpaks
    @ujust clone-dotfiles
    @ujust configure-git-identity
    @ujust set-default-shell
    @ujust setup-tailscale
    @ujust copy-cosmic-config

[group('Setup')]
setup-interactive:
    #!/usr/bin/env bash
    set -euxo pipefail

    choices=$(gum choose --no-limit \
        "install-default-brew" \
        "install-default-flatpaks" \
        "clone-dotfiles" \
        "configure-git-identity" \
        "set-default-shell" \
        "setup-tailscale" \
        "copy-cosmic-config")

    for choice in $choices; do
        ujust $choice
    done

# justfile to create editor shortcuts
# Path for .desktop files

desktop_dir := '~/.local/share/applications'

# Creates VS Code shortcuts for projects in a directory.

# Usage: just code_shortcut [directory]
[group('Util')]
code_shortcut directory='$HOME/projects':
    @ujust _create_shortcut 'code' {{ directory }}

# Creates Zed shortcuts for projects in a directory.

# Usage: just zed_shortcut [directory]
[group('Util')]
zed_shortcut directory='$HOME/projects':
    @ujust _create_shortcut 'zed' {{ directory }}

# --- Helper recipe ---

# Recipe to create a shortcut for a given directory
_create_shortcut editor directory:
    #!/bin/bash
    set -euo pipefail

    EDITOR_APP='{{ editor }}'
    PROJECT_PATH_RAW='{{ directory }}'

    PROJECT_PATH=$(eval echo "$PROJECT_PATH_RAW")
    DESKTOP_DIR_EXPANDED=$(eval echo "{{ desktop_dir }}")

    if [ ! -d "$PROJECT_PATH" ]; then
        echo "Error: The directory '$PROJECT_PATH' does not exist."
        exit 1
    fi

    mkdir -p "$DESKTOP_DIR_EXPANDED"

    project_name=$(basename "$PROJECT_PATH")

    exec_command=""
    icon_name=""
    app_name=""
    comment_text=""

    case "$EDITOR_APP" in
        "code")
            exec_command="/usr/bin/code --new-window"
            icon_name="visual-studio-code"
            app_name="Code"
            comment_text="Open Visual Studio Code project"
            ;;
        "zed")
            exec_command="/home/boris/.local/bin/zed --new"
            icon_name="zed"
            app_name="Zed"
            comment_text="Open Zed editor project"
            ;;
        *)
            echo "Error: Unsupported editor specified: $EDITOR_APP"
            exit 1
            ;;
    esac

    desktop_filename="${EDITOR_APP}-${project_name}.desktop"
    desktop_filepath="$DESKTOP_DIR_EXPANDED/$desktop_filename"

    # Create the content for the .desktop file
    printf "[Desktop Entry]\n" > "$desktop_filepath"
    printf "Version=1.0\n" >> "$desktop_filepath"
    printf "Name=%s %s\n" "$app_name" "$project_name" >> "$desktop_filepath"
    printf "Comment=%s %s\n" "$comment_text" "$project_name" >> "$desktop_filepath"
    printf "Exec=%s %s\n" "$exec_command" "$PROJECT_PATH" >> "$desktop_filepath"
    printf "Icon=%s\n" "$icon_name" >> "$desktop_filepath"
    printf "Type=Application\n" >> "$desktop_filepath"
    printf "Terminal=false\n" >> "$desktop_filepath"
    printf "Categories=Development;\n" >> "$desktop_filepath"

    # Make the .desktop file executable
    chmod +x "$desktop_filepath"

    echo "Created shortcut for: '$project_name'"

    echo "Script finished. Your $EDITOR_APP project shortcut is now available in your application launcher."
