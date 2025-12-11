# Module: setup_ssh_and_github
MODULE_DEPS="gh git"

setup_ssh_and_github() {
    if ! gum confirm "Do you want to set up GitHub login and SSH now?" 2> /dev/tty; then
        clear_info
        return
    fi
    # Checks if the host is present. If it's NOT present (using '&& !'), then keyscan is run.
    mkdir -p ~/.ssh
    ssh-keygen -F github.com 2>/dev/null >/dev/null || ssh-keyscan github.com >> ~/.ssh/known_hosts
    local SSH_KEY="$HOME/.ssh/github"
    eval "$(ssh-agent -s)" &> /dev/null
    if [ ! -f "$SSH_KEY" ]; then
        log_and_spin "Generating SSH key..." bash -c "ssh-keygen -t ed25519 -f \"$SSH_KEY\" -N \"\" && ssh-add \"$SSH_KEY\""
    fi

    if ! gh auth status &> /dev/null; then
        gh auth login -s admin:public_key -p ssh --skip-ssh-key -wc
        clear_info
    fi

    if ! gh ssh-key list | grep -q "$(cat "$SSH_KEY.pub" | awk '{print $2}')"; then
        log_and_spin "Uploading SSH key to GitHub..." \
            gh ssh-key add "$SSH_KEY.pub" --title "Linux-Desktop-BOS$(date +%Y-%m-%d)"
    fi
}
