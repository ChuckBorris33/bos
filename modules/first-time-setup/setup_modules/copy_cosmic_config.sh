# Module: copy_cosmic_config

copy_cosmic_config() {
    gum style --bold --foreground "212" "Copying COSMIC config..."
    local source_dir="/usr/share/cosmic"
    local dest_dir="$HOME/.config/cosmic"

    if [ -d "$source_dir" ]; then
        mkdir -p "$dest_dir"
        log_and_spin "Copying COSMIC files..." \
            cp -rfT "$source_dir" "$dest_dir"
        clear_info
    else
        gum style --bold --foreground "226" "Warning: $source_dir not found. Skipping COSMIC config copy."
        sleep 2
        clear_info
    fi
}
