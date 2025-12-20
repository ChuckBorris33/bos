[group('Setup')]
login-gh:
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if gh CLI is installed, if not, install it with brew
    if ! command -v gh &> /dev/null; then
        echo "GitHub CLI 'gh' not found."
        if ! command -v brew &> /dev/null; then
            echo "Error: Homebrew 'brew' is not installed. Cannot install 'gh'." >&2
            exit 1
        fi
        echo "Installing GitHub CLI 'gh' with Homebrew..."
        brew install gh
    fi

    # Check if user is logged into gh
    if gh auth status &>/dev/null; then
        echo "Already logged into GitHub."
    else
        echo "You are not logged into GitHub."
        echo "Please follow the prompts to login."
        gh auth login
    fi

[group('Setup')]
clone-dotfiles:
    #!/usr/bin/env bash
    DOTFILES_REPO="https://github.com/ChuckBorris33/dotfiles.git"

    if [ -z "$DOTFILES_REPO" ] || [ "$DOTFILES_REPO" = "null" ]; then
        exit 0
    fi

    if [ -d "$HOME/.local/share/yadm/repo.git" ]; then
        echo "Pulling latest changes for dotfiles..."
        yadm pull
    else
        echo "Cloning dotfiles with yadm..."
        yadm clone "$DOTFILES_REPO" --no-bootstrap -f
    fi

    echo "Bootstrapping yadm..."
    yadm bootstrap

[group('Setup')]
configure-git-identity:
    #!/usr/bin/env bash
    echo "Configuring global Git identity..."

    current_name=$(git config --global user.name || echo "")
    current_email=$(git config --global user.email || echo "")

    echo "Current Git Identity:"
    echo "Name: $current_name"
    echo "Email: $current_email"

    if gum confirm "Do you want to change your Git identity?"; then
        new_name=$(gum input --placeholder "Full name for git commits" --value "$current_name")
        git config --global user.name "$new_name"

        new_email=$(gum input --placeholder "Email for git commits" --value "$current_email")
        git config --global user.email "$new_email"
    fi

[group('Setup')]
set-default-shell:
    #!/usr/bin/env bash
    desired_shell="zsh"

    if [ -n "$desired_shell" ] && command -v "$desired_shell" &>/dev/null; then
        shell_path="$(which "$desired_shell")"
        if [ "$(basename "$SHELL")" != "$desired_shell" ]; then
            echo "Changing default shell to $desired_shell..."
            if chsh -s "$shell_path"; then
                echo "Shell changed successfully."
            else
                echo "Failed to change shell."
            fi
        fi
    fi

[group('Setup')]
setup-tailscale:
    #!/usr/bin/env bash
    set -euxo pipefail

    if tailscale status &>/dev/null; then
        echo "Tailscale is already configured. Skipping."
        exit 0
    fi

    echo "Tailscale Setup"
    echo "You can get an auth key from your Tailscale admin console:"
    echo "https://login.tailscale.com/admin/settings/keys"

    auth_key=$(gum input --password --placeholder="Paste auth key (leave empty to skip)...")

    if [ -z "$auth_key" ]; then
        exit 0
    fi

    echo "Connecting to Tailscale..."
    sudo systemctl start tailscaled
    sudo tailscale up --authkey="$auth_key" --hostname="bos-$(hostname)"
