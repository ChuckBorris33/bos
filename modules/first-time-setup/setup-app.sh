#!/bin/bash

# Part 1: Relaunch in Alacritty if needed
# -----------------------------------------------------------------------------
# If not running inside the special alacritty session, relaunch into it.
if [ -z "$IS_IN_ALACRITTY" ]; then
    export IS_IN_ALACRITTY=true
    # Get the absolute path of the script to handle relative paths
    SCRIPT_PATH=$(readlink -f "$0")
    alacritty --class Guake -e "$SCRIPT_PATH"
    exit 0
fi

# Part 2: Main script logic
# -----------------------------------------------------------------------------

CONFIG_FILE="files/first_time_setup_config.yaml"

# --- UI Functions ---

print_art() {
cat << "EOF"
================================================================================



                          ██████╗  ██████╗  ██████╗
                          ██╔══██╗██╔═══██╗██╔════╝
                          ██████╔╝██║   ██║╚█████╗
                          ██╔══██╗██║   ██║ ╚═══██╗
                          ██████╔╝╚██████╔╝██████╔╝
                          ╚═════╝  ╚═════╝ ╚═════╝

                                Boris's OS
                           First time boot script



================================================================================
EOF
}

redraw_screen() {
    clear
    local total_lines
    total_lines=$(tput lines)
    local available_height=$((total_lines - 2))
    local ascii_art_height=18
    local top_padding=$(( (available_height - ascii_art_height) / 2 ))
    [ $top_padding -lt 0 ] && top_padding=0

    for ((i=0; i<top_padding; i++)); do echo ""; done
    print_art
    tput cup $((total_lines - 3)) 0
}

# --- Setup Functions ---

check_dependencies() {
    gum style --bold --foreground "212" "Checking for dependencies..."
    for tool in gum yq flatpak brew gh; do
        if ! command -v "$tool" &> /dev/null; then
            gum style --bold --foreground "196" --padding "1 2" --border thick --border-foreground "196" "Error: '$tool' is not installed. Please install it and run the script again."
            exit 1
        fi
    done
}

install_flatpaks() {
    if [ -n "$(yq e '.flatpak_remotes[]' "$CONFIG_FILE")" ]; then
        gum style --bold --foreground "212" "Installing Flatpak applications..."
        local total_apps=0
        local app_lengths
        app_lengths=$(yq e '.flatpak_remotes[].apps | length' "$CONFIG_FILE" 2>/dev/null || echo "")
        if [ -n "$app_lengths" ]; then
          for length in $app_lengths; do
            total_apps=$((total_apps + length))
          done
        fi
        local app_counter=0
        local remotes_count
        remotes_count=$(yq e '.flatpak_remotes | length' "$CONFIG_FILE")

        for i in $(seq 0 $((remotes_count - 1))); do
            local remote_name remote_url
            remote_name=$(yq e ".flatpak_remotes[$i].name" "$CONFIG_FILE")
            remote_url=$(yq e ".flatpak_remotes[$i].url" "$CONFIG_FILE")

            if [[ -n "$remote_name" && -n "$remote_url" ]] && ! flatpak remotes --user | grep -q "^$remote_name "; then
                gum spin --spinner dot --title "Adding Flatpak remote '$remote_name'..." -- \
                    flatpak remote-add --user --if-not-exists "$remote_name" "$remote_url"
            fi

            local apps_count
            apps_count=$(yq e ".flatpak_remotes[$i].apps | length" "$CONFIG_FILE")
            if [ "$apps_count" -gt 0 ]; then
                for j in $(seq 0 $((apps_count - 1))); do
                    local app_id
                    app_id=$(yq e ".flatpak_remotes[$i].apps[$j]" "$CONFIG_FILE")
                    app_counter=$((app_counter + 1))
                    local title="Installing flatpak ($app_counter/$total_apps): $app_id"
                    gum spin --spinner dot --title "$title" -- \
                        flatpak install --user "$remote_name" -y "$app_id"
                done
            fi
        done
    fi
}

install_brew_packages() {
    local formulae_to_install
    formulae_to_install=($(yq e '.brew.formulae[]' "$CONFIG_FILE" 2>/dev/null))
    local total_formulae=${#formulae_to_install[@]}

    if [ "$total_formulae" -gt 0 ]; then
        gum style --bold --foreground "212" "Installing brew formulae..."
        local current_formula_index=1
        for formula in "${formulae_to_install[@]}"; do
            local title="Installing brew formula ($current_formula_index/$total_formulae): $formula"
            gum spin --spinner dot --title "$title" -- brew install "$formula"
            ((current_formula_index++))
        done
    fi
}

set_default_shell() {
    local desired_shell
    desired_shell=$(yq e '.shell' "$CONFIG_FILE")

    if [ -n "$desired_shell" ] && command -v "$desired_shell" &>/dev/null; then
        local shell_path
        shell_path="$(which "$desired_shell")"
        if [ "$(basename "$SHELL")" != "$desired_shell" ]; then
            gum style --bold --foreground "212" "Setting default shell to $desired_shell..."
            chsh -s "$shell_path"
        fi
    fi
}

setup_ssh_and_github() {
    gum style --bold --foreground "212" "Setting up SSH key and GitHub..."
    local SSH_KEY="$HOME/.ssh/github"
    eval "$(ssh-agent -s)" &> /dev/null
    if [ ! -f "$SSH_KEY" ]; then
        gum spin --spinner dot --title "Generating SSH key..." -- bash -c "ssh-keygen -t ed25519 -f \"$SSH_KEY\" -N \"\" && ssh-add \"$SSH_KEY\""
    fi

    if ! gh auth status &> /dev/null; then
        gh auth login -s admin:public_key -p ssh --skip-ssh-key -w -c
        redraw_screen
    fi

    if ! gh ssh-key list | grep -q "$(cat "$SSH_KEY.pub" | awk '{print $2}')"; then
        gum spin --spinner dot --title "Uploading SSH key to GitHub..." -- \
            gh ssh-key add "$SSH_KEY.pub" --title "Linux-Desktop-BOS$(date +%Y-%m-%d)"
    else
        gum style "SSH key already exists on GitHub."
    fi
}

clone_dotfiles() {
    if [ ! -d "$HOME/.local/share/yadm/repo.git" ]; then
        gum style --bold --foreground "212" "Cloning dotfiles..."
        local DOTFILES_REPO
        DOTFILES_REPO=$(yq e '.dotfiles_repo' "$CONFIG_FILE")
        gum spin --spinner dot --title "Cloning dotfiles with yadm..." -- \
            yadm clone "$DOTFILES_REPO" -f
        gum spin --spinner dot --title "Bootstrapping yadm..." -- yadm bootstrap
    else
        gum style "Yadm repo already exists."
    fi
}

# --- Main Function ---

main() {
    redraw_screen
    check_dependencies
    install_flatpaks
    install_brew_packages
    set_default_shell
    redraw_screen
    setup_ssh_and_github
    clone_dotfiles
    gum style --bold --foreground "212" "First time setup complete!"
}

main
