#!/bin/bash
set -euo pipefail

# --- Pre-computation and setup ---
if [ ! -d "/usr/libexec/bootc-hooks" ]; then
    echo "Error: This module depends on the bootc-hooks module, but the /usr/libexec/bootc-hooks directory was not found." >&2
    exit 1
fi

CONFIG_PATH="/etc/first_time_setup/config.yaml"
MODULE_SOURCE_DIR="$MODULE_DIRECTORY/first-time-setup/setup_modules"
GENERATED_SCRIPT_PATH="/usr/local/bin/first-time-setup-generated.sh"
JSON_STRING=$1

# The script is executed by bootc-hook which runs as root
CONFIG_DIR=$(dirname "$CONFIG_PATH")
mkdir -p "$CONFIG_DIR"

# Install core dependencies needed for the setup script to run at all
# Other dependencies are checked dynamically based on selected modules
dnf install -y gum yq gh git

# Convert JSON to YAML and save to file
echo "Converting JSON config to YAML at $CONFIG_PATH"
echo "$JSON_STRING" | yq -p json -o yaml > "$CONFIG_PATH"

# --- Script Generation ---
echo "Generating the first-time setup script at $GENERATED_SCRIPT_PATH"

# 1. Start with the utility script content (shebang, UI functions, etc.)
cat "$MODULE_DIRECTORY/first-time-setup/setup-app.sh" > "$GENERATED_SCRIPT_PATH"

# 2. Get the list of modules to include from the config and aggregate their dependencies
MODULE_NAMES=$(yq e '.modules | keys | .[]' "$CONFIG_PATH")
ALL_DEPS=""

for MODULE_NAME in $MODULE_NAMES; do
    MODULE_FILE="$MODULE_SOURCE_DIR/${MODULE_NAME}.sh"
    if [ -f "$MODULE_FILE" ]; then
        # Extract dependencies from the module file, if they exist
        MOD_DEPS=$(grep '^MODULE_DEPS=' "$MODULE_FILE" | cut -d'=' -f2 | tr -d '"' || true)
        if [ -n "$MOD_DEPS" ]; then
            ALL_DEPS="$ALL_DEPS $MOD_DEPS"
        fi
    fi
done

# 3. Append each module's function definition to the script
for MODULE_NAME in $MODULE_NAMES; do
    MODULE_FILE="$MODULE_SOURCE_DIR/${MODULE_NAME}.sh"
    if [ -f "$MODULE_FILE" ];
    then
        echo "Appending module definition: $MODULE_NAME"
        echo "" >> "$GENERATED_SCRIPT_PATH"
        echo "# --- Module Definition: $MODULE_NAME ---" >> "$GENERATED_SCRIPT_PATH"
        cat "$MODULE_FILE" >> "$GENERATED_SCRIPT_PATH"
    else
        echo "Warning: Module script not found for '$MODULE_NAME', skipping."
    fi
done

# 4. Get a unique, sorted list of all dependencies, plus 'gum' which is essential
UNIQUE_DEPS=$(echo "gum $ALL_DEPS" | tr ' ' '\n' | sort -u | tr '\n' ' ')

# 5. Append the dependency checker function
echo "Appending dependency checker for: $UNIQUE_DEPS"
cat >> "$GENERATED_SCRIPT_PATH" <<EOF

# --- Generated Functions ---

check_all_dependencies() {
    gum style --bold --foreground "212" "Checking for required tools..."
    for tool in $UNIQUE_DEPS; do
        if ! command -v "\$tool" &> /dev/null; then
            gum style --bold --foreground "196" --padding "1 2" --border thick --border-foreground "196" "Error: Required tool '\$tool' is not installed. Please fix the image and try again."
            exit 1
        fi
    done
    clear_info
}
EOF

# 6. Append the main execution logic
echo "Appending main execution logic"
cat >> "$GENERATED_SCRIPT_PATH" <<'EOF'

main() {
    sleep 0.5
    draw_screen
    check_all_dependencies
EOF

# 7. Append calls to each module's function
for MODULE_NAME in $MODULE_NAMES; do
    echo "    $MODULE_NAME" >> "$GENERATED_SCRIPT_PATH"
    echo "    draw_screen" >> "$GENERATED_SCRIPT_PATH"
done

# 8. Append the final closing block
cat >> "$GENERATED_SCRIPT_PATH" <<'EOF'

    gum style --bold --foreground "212" "First time setup complete!"
    if gum confirm "Do you want to restart now?" 2> /dev/tty; then
        log_and_spin "Rebooting..." sudo systemctl reboot
    else
        gum style --foreground "226" "You can reboot later to apply all changes."
    fi
}

main
EOF

# --- Installation ---
echo "Installing the generated script"
chmod +x "$GENERATED_SCRIPT_PATH"

HOOKS_DIR="/usr/libexec/bootc-hooks/user/switch"
mkdir -p "$HOOKS_DIR"
cp "$GENERATED_SCRIPT_PATH" "$HOOKS_DIR/first-time-setup.sh"

echo "First-time setup script has been generated and installed successfully."
