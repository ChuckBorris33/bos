# Configuration Script for Brew Install Module (Based on BrewInstallModuleV1 Schema)

# The input is expected to be a JSON string in the first argument ($1).

# Module-specific directories and paths
MODULE_DIRECTORY="${MODULE_DIRECTORY:-/tmp/modules}"

# ----------------------------------------------------------------------
# 1. MODULE_OPTIONS (The list of command-line options for 'brew install')
#    (Defaults to an empty JSON array: [])
# ----------------------------------------------------------------------
# Note: When jq extracts an array, it returns a JSON string like '["--force", "--verbose"]'
MODULE_OPTIONS=$(echo "${1}" | jq -r 'try .["options"]')
if [[ -z "${MODULE_OPTIONS}" || "${MODULE_OPTIONS}" == "null" ]]; then
    # Default to an empty JSON array string
    MODULE_OPTIONS="[]"
fi

# ----------------------------------------------------------------------
# 2. MODULE_INSTALL (The list of packages to be installed by Brew)
#    (Defaults to an empty JSON array: [])
# ----------------------------------------------------------------------
MODULE_INSTALL=$(echo "${1}" | jq -r 'try .["install"]')
if [[ -z "${MODULE_INSTALL}" || "${MODULE_INSTALL}" == "null" ]]; then
    # Default to an empty JSON array string
    MODULE_INSTALL="[]"
fi

# ----------------------------------------------------------------------
# 3. SCRIPT CREATION, PERMISSIONS, AND COMMAND POPULATION
# ----------------------------------------------------------------------
TARGET_SCRIPT="/usr/libexec/bluebuild/brew-install"

# Check if the script file exists
if ! [ -f "${TARGET_SCRIPT}" ]; then
    echo "Script file ${TARGET_SCRIPT} not found. Creating and setting executable."
    # 1. Ensure the parent directory exists
    mkdir -p "$(dirname "${TARGET_SCRIPT}")"
    # 2. Create the file and set executable
    touch "${TARGET_SCRIPT}"
    chmod +x "${TARGET_SCRIPT}"
    # 3. Start the file with the shebang
    echo '#!/bin/bash' > "${TARGET_SCRIPT}"
    echo '# This script executes the configured Homebrew installations.' >> "${TARGET_SCRIPT}"
else
    # Ensure executable if it already exists
    echo "Script file ${TARGET_SCRIPT} already exists. Ensuring executable permission."
    chmod +x "${TARGET_SCRIPT}"
fi

# Convert JSON arrays to space-separated lists for the command string
# We use 'tr' to replace newlines (which jq -r introduces for each array element) with spaces.
OPTIONS_LIST=$(echo "${MODULE_OPTIONS}" | jq -r '.[]' | tr '\n' ' ')
PACKAGES_LIST=$(echo "${MODULE_INSTALL}" | jq -r '.[]' | tr '\n' ' ')

# Construct the full command
BREW_COMMAND="/home/linuxbrew/.linuxbrew/bin/brew install ${OPTIONS_LIST} ${PACKAGES_LIST}"

# Append the command and print statements (as requested by the user)
echo "" >> "${TARGET_SCRIPT}"
echo "# --- Configuration applied on $(date) ---" >> "${TARGET_SCRIPT}"
echo "echo \"Starting configured brew installation with: ${BREW_COMMAND}\"" >> "${TARGET_SCRIPT}"
echo "${BREW_COMMAND}" >> "${TARGET_SCRIPT}"
echo "if [ \$? -eq 0 ]; then" >> "${TARGET_SCRIPT}"
echo "    echo \"Brew installation completed successfully.\"" >> "${TARGET_SCRIPT}"
echo "else" >> "${TARGET_SCRIPT}"
echo "    echo \"Brew installation failed.\" >&2" >> "${TARGET_SCRIPT}"
echo "fi" >> "${TARGET_SCRIPT}"
echo "echo \"Installation command finished.\"" >> "${TARGET_SCRIPT}"


# ----------------------------------------------------------------------
# 4. CONDITIONAL SYSTEMD FILE COPY LOGIC
# ----------------------------------------------------------------------
# NOTE: MODULE_DIRECTORY must be defined elsewhere in your execution environment.
TARGET_DIR="/usr/lib/systemd/system"

# --- Conditional Copy for Service File ---
SERVICE_FILE="brew-install-setup.service"
SOURCE_SERVICE_PATH="${MODULE_DIRECTORY}/brew-install/post-boot/${SERVICE_FILE}"
TARGET_SERVICE_PATH="${TARGET_DIR}/${SERVICE_FILE}"

# The core check: '! [ -f ... ]' checks if the file DOES NOT exist.
if ! [ -f "${TARGET_SERVICE_PATH}" ]; then
    echo "Service file not found at target. Copying: ${SERVICE_FILE}"
    # Perform the copy operation
    cp "${SOURCE_SERVICE_PATH}" "${TARGET_SERVICE_PATH}"
else
    echo "Service file already exists at target: ${TARGET_SERVICE_PATH}. Skipping copy."
fi

# --- Conditional Copy for Timer File ---
TIMER_FILE="brew-install-setup.timer"
SOURCE_TIMER_PATH="${MODULE_DIRECTORY}/brew-install/post-boot/${TIMER_FILE}"
TARGET_TIMER_PATH="${TARGET_DIR}/${TIMER_FILE}"

if ! [ -f "${TARGET_TIMER_PATH}" ]; then
    echo "Timer file not found at target. Copying: ${TIMER_FILE}"
    # Perform the copy operation
    cp "${SOURCE_TIMER_PATH}" "${TARGET_TIMER_PATH}"
else
    echo "Timer file already exists at target: ${TARGET_TIMER_PATH}. Skipping copy."
fi

# ----------------------------------------------------------------------
# 5. SYSTEMD SETUP (Post-Copy)
# ----------------------------------------------------------------------

# Reload systemd manager configuration to recognize new files
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable the timer so it starts automatically at boot and runs on schedule
if [ -f "${TARGET_TIMER_PATH}" ]; then
    echo "Enabling and starting the timer: ${TIMER_FILE}"
    systemctl enable --force "${TIMER_FILE}"
else
    echo "Timer file not copied, skipping systemd setup."
fi
