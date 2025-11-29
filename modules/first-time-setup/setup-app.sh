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

CONFIG_FILE="/etc/first_time_setup/config.yaml"

# --- UI Functions ---

print_art() {
    local cols lines inner_height border_line
    cols=$(tput cols 2>/dev/null || echo 80)
    lines=$(tput lines 2>/dev/null || echo 24)
    # Inner vertical space between the two '=' border lines
    inner_height=$((lines - 5))
    ((inner_height < 1)) && inner_height=1

    # Build a full-width '=' border line
    border_line=$(printf '%*s' "$cols" '' | tr ' ' '=')

    # ASCII art content lines (logo + text)
    local -a art=(
"██████╗  ██████╗  ██████╗"
"██╔══██╗██╔═══██╗██╔════╝"
"██████╔╝██║   ██║╚█████╗ "
"██╔══██╗██║   ██║ ╚═══██╗"
"██████╔╝╚██████╔╝██████╔╝"
"╚═════╝  ╚═════╝ ╚═════╝ "
""
"Boris's OS"
"First time boot script"
    )

    local art_lines=${#art[@]}
    local display_art_lines=$art_lines

    # If terminal height too small, truncate art
    if (( inner_height < art_lines )); then
        display_art_lines=$inner_height
    fi

    local blank_lines=$((inner_height - display_art_lines))
    ((blank_lines < 0)) && blank_lines=0
    local top_pad=$((blank_lines / 2))
    local bottom_pad=$((blank_lines - top_pad))

    echo "$border_line"

    # Top padding
    for ((i=0; i<top_pad; i++)); do echo ""; done

    # Art (possibly truncated)
    for ((i=0; i<display_art_lines; i++)); do
        raw="${art[i]}"
        if [ -z "$raw" ]; then
            echo ""
        else
            trimmed="$(printf '%s' "$raw" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            line_len=${#trimmed}
            if (( line_len > cols )); then
                trimmed="${trimmed:0:cols}"
                line_len=${#trimmed}
            fi
            pad=$(( (cols - line_len) / 2 ))
            ((pad < 0)) && pad=0
            printf "%*s%s\n" "$pad" "" "$trimmed"
        fi
    done

    # Bottom padding
    for ((i=0; i<bottom_pad; i++)); do echo ""; done

    echo "$border_line"
}

draw_screen() {
    clear
    print_art
    # Position cursor three lines from bottom for subsequent interactive output
    local total_lines
    total_lines=$(tput lines 2>/dev/null || echo 24)
    tput cup $((total_lines - 3)) 0 2>/dev/null || true
}

clear_info() {
    local total_lines
    total_lines=$(tput lines 2>/dev/null || echo 24)
    tput cup $((total_lines - 3)) 0 2>/dev/null || true
    tput ed
    tput cup $((total_lines - 3)) 0 2>/dev/null || true
}

# --- Setup Functions ---

check_dependencies() {
    gum style --bold --foreground "212" "Checking for dependencies..."
    for tool in gum yq flatpak brew gh git; do
        if ! command -v "$tool" &> /dev/null; then
            gum style --bold --foreground "196" --padding "1 2" --border thick --border-foreground "196" "Error: '$tool' is not installed. Please install it and run the script again."
            exit 1
        fi
    done
    clear_info
}

install_flatpaks() {
    if [ -n "$(yq e '.flatpak_remotes[]' "$CONFIG_FILE")" ]; then
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
            chsh -s "$shell_path"
        fi
    fi
}

setup_ssh_and_github() {
    # Checks if the host is present. If it's NOT present (using '&& !'), then keyscan is run.
    ssh-keygen -F github.com 2>/dev/null >/dev/null || ssh-keyscan github.com >> ~/.ssh/known_hosts
    local SSH_KEY="$HOME/.ssh/github"
    eval "$(ssh-agent -s)" &> /dev/null
    if [ ! -f "$SSH_KEY" ]; then
        gum spin --spinner dot --title "Generating SSH key..." -- bash -c "ssh-keygen -t ed25519 -f \"$SSH_KEY\" -N \"\" && ssh-add \"$SSH_KEY\""
    fi

    if ! gh auth status &> /dev/null; then
        gh auth login -s admin:public_key -p ssh --skip-ssh-key -wc
        clear_info
    fi

    if ! gh ssh-key list | grep -q "$(cat "$SSH_KEY.pub" | awk '{print $2}')"; then
        gum spin --spinner dot --title "Uploading SSH key to GitHub..." -- \
            gh ssh-key add "$SSH_KEY.pub" --title "Linux-Desktop-BOS$(date +%Y-%m-%d)"
    fi
}

configure_git_identity() {
    gum style --bold --foreground "212" "Configuring global Git identity..."

    local current_name
    current_name=$(git config --global user.name)
    local current_email
    current_email=$(git config --global user.email)

    gum style --padding "1 2" --border normal --border-foreground "212" \
        "Current Git Identity:" "Name: $current_name" "Email: $current_email"

    if gum confirm "Do you want to change your Git identity?"; then
        clear_info
        # user.name
        new_name=$(gum input --placeholder "Full name for git commits" --value "$current_name")
        git config --global user.name "$new_name"
        clear_info

        gum style --bold --foreground "212" "Configuring global Git identity..."

        # user.email
        new_email=$(gum input --placeholder "Email for git commits" --value "$current_email")
        git config --global user.email "$new_email"
        clear_info
    else
        clear_info
    fi
}

clone_dotfiles() {
    if [ ! -d "$HOME/.local/share/yadm/repo.git" ]; then
        local DOTFILES_REPO
        DOTFILES_REPO=$(yq e '.dotfiles_repo' "$CONFIG_FILE")
        gum spin --spinner dot --title "Cloning dotfiles with yadm..." -- \
            yadm --no-bootstrap clone "$DOTFILES_REPO" -f
        gum spin --spinner dot --title "Bootstrapping yadm..." -- yadm bootstrap
    fi
}

copy_cosmic_config() {
    gum style --bold --foreground "212" "Copying COSMIC config..."
    local source_dir="/usr/share/cosmic"
    local dest_dir="$HOME/.config/cosmic"

    if [ -d "$source_dir" ]; then
        mkdir -p "$dest_dir"
        gum spin --spinner dot --title "Copying COSMIC files..." -- \
            cp -rfT "$source_dir" "$dest_dir"
        clear_info
    else
        gum style --bold --foreground "226" "Warning: $source_dir not found. Skipping COSMIC config copy."
        sleep 2
        clear_info
    fi
}

# --- Main Function ---

main() {
    sleep 0.3
    draw_screen
    check_dependencies
    copy_cosmic_config
    draw_screen
    install_flatpaks
    install_brew_packages
    set_default_shell
    draw_screen

    # Attempt to clone dotfiles first; if it fails, set up SSH/GitHub and retry
    clone_dotfiles
    if [ ! -d "$HOME/.local/share/yadm/repo.git" ]; then
        draw_screen
        setup_ssh_and_github
        draw_screen
        clone_dotfiles
    fi

    draw_screen
    configure_git_identity
    draw_screen

    gum style --bold --foreground "212" "First time setup complete!"
    if gum confirm "Do you want to restart now?"; then
        gum spin --spinner dot --title "Rebooting..." -- sudo systemctl reboot
    else
        gum style --foreground "226" "You can reboot later to apply all changes."
    fi
}

main
