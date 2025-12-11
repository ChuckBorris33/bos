# Module: configure_git_identity
MODULE_DEPS="git"

configure_git_identity() {
    gum style --bold --foreground "212" "Configuring global Git identity..."

    local current_name
    current_name=$(git config --global user.name || echo "")
    local current_email
    current_email=$(git config --global user.email || echo "")

    gum style --padding "1 2" --border normal --border-foreground "212" \
        "Current Git Identity:" "Name: $current_name" "Email: $current_email"

    if gum confirm "Do you want to change your Git identity?" 2> /dev/tty; then
        clear_info
        # user.name
        new_name=$(gum input --placeholder "Full name for git commits" --value "$current_name" 2> /dev/tty)
        git config --global user.name "$new_name"
        clear_info

        gum style --bold --foreground "212" "Configuring global Git identity..."

        # user.email
        new_email=$(gum input --placeholder "Email for git commits" --value "$current_email" 2> /dev/tty)
        git config --global user.email "$new_email"
        clear_info
    else
        clear_info
    fi
}
