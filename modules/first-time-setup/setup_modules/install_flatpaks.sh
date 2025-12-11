# Module: install_flatpaks
MODULE_DEPS="yq flatpak"

install_flatpaks() {
    if [ -n "$(yq e '.install_flatpaks.remotes[]' "$CONFIG_FILE")" ]; then
        local total_apps=0
        local app_lengths
        app_lengths=$(yq e '.install_flatpaks.remotes[].apps | length' "$CONFIG_FILE" 2>/dev/null || echo "")
        if [ -n "$app_lengths" ]; then
          for length in $app_lengths; do
            total_apps=$((total_apps + length))
          done
        fi
        local app_counter=0
        local remotes_count
        remotes_count=$(yq e '.install_flatpaks.remotes | length' "$CONFIG_FILE")

        for i in $(seq 0 $((remotes_count - 1))); do
            local remote_name remote_url
            remote_name=$(yq e ".install_flatpaks.remotes[$i].name" "$CONFIG_FILE")
            remote_url=$(yq e ".install_flatpaks.remotes[$i].url" "$CONFIG_FILE")

            if [[ -n "$remote_name" && -n "$remote_url" ]] && ! flatpak remotes --user | grep -q "^$remote_name "; then
                log_and_spin "Adding Flatpak remote '$remote_name'..." \
                    flatpak remote-add --user --if-not-exists "$remote_name" "$remote_url"
            fi

            local apps_count
            apps_count=$(yq e ".install_flatpaks.remotes[$i].apps | length" "$CONFIG_FILE")
            if [ "$apps_count" -gt 0 ]; then
                for j in $(seq 0 $((apps_count - 1))); do
                    local app_id
                    app_id=$(yq e ".install_flatpaks.remotes[$i].apps[$j]" "$CONFIG_FILE")
                    app_counter=$((app_counter + 1))
                    local title="Installing flatpak ($app_counter/$total_apps): $app_id"
                    log_and_spin "$title" \
                        flatpak install --user "$remote_name" -y "$app_id"
                done
            fi
        done
    fi
}
