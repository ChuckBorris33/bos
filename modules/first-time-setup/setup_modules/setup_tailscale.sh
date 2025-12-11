# Module: install_tailscale
MODULE_DEPS="tailscale"

install_tailscale() {
    # Check if tailscale is already running and configured
    if tailscale status &>/dev/null; then
        gum style --bold --foreground "212" "Tailscale is already configured. Skipping."
        sleep 1
        return
    fi

    gum style --bold --padding "1 2" --border normal --border-foreground "212" \
        "Tailscale Setup" \
        "You can get an auth key from your Tailscale admin console:" \
        "https://login.tailscale.com/admin/settings/keys"

    local auth_key
    auth_key=$(gum input --password --placeholder="Paste auth key (leave empty to skip)..." 2>/dev/tty)

    if [ -z "$auth_key" ]; then
        clear_info
        return
    fi

    log_and_spin "Connecting to Tailscale..." \
        tailscale up --authkey="$auth_key" --hostname="bos-$(hostname)"
}
