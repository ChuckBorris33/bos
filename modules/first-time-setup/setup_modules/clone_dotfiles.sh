# Module: clone_dotfiles
MODULE_DEPS="yq yadm"

clone_dotfiles() {
    local DOTFILES_REPO
    DOTFILES_REPO=$(yq e '.clone_dotfiles.repo' "$CONFIG_FILE" 2>/dev/null || true)

    if [ -z "$DOTFILES_REPO" ] || [ "$DOTFILES_REPO" = "null" ]; then
        return
    fi

    if [ -d "$HOME/.local/share/yadm/repo.git" ]; then
        log_and_spin "Pulling latest changes for dotfiles..." yadm pull
    else
        if ! log_and_spin "Cloning dotfiles with yadm..." \
            yadm clone "$DOTFILES_REPO" --no-bootstrap -f; then
            return
        fi
    fi

    log_and_spin "Bootstrapping yadm..." yadm bootstrap
}
