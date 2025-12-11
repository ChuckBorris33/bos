# Module: install_brew_packages
MODULE_DEPS="yq brew"

install_brew_packages() {
    local formulae_to_install
    formulae_to_install=($(yq e '.install_brew_packages.formulae[]' "$CONFIG_FILE" 2>/dev/null))
    local total_formulae=${#formulae_to_install[@]}

    if [ "$total_formulae" -gt 0 ]; then
        local current_formula_index=1
        for formula in "${formulae_to_install[@]}"; do
            local title="Installing brew formula ($current_formula_index/$total_formulae): $formula"
            log_and_spin "$title" brew install "$formula"
            ((current_formula_index++))
        done
    fi
}
