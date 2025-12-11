# Module: set_default_shell
MODULE_DEPS="yq"

set_default_shell() {
    local desired_shell
    desired_shell=$(yq e '.set_default_shell.shell' "$CONFIG_FILE")

    if [ -n "$desired_shell" ] && command -v "$desired_shell" &>/dev/null; then
        local shell_path
        shell_path="$(which "$desired_shell")"
        if [ "$(basename "$SHELL")" != "$desired_shell" ]; then
            gum style --bold --foreground "212" "Changing default shell to $desired_shell..."
            if chsh -s "$shell_path"; then
                gum style --foreground "212" "Shell changed successfully."
            else
                gum style --foreground "196" "Failed to change shell."
            fi
        fi
    fi
}
