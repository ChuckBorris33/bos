# Replace <PROFILE_PATH> with your actual profile directory
PROFILE_PATH="/path/to/your/profile.default-release"
PREFS_FILE="$PROFILE_PATH/prefs.js"

# Define the preferences to set to true (boolean)
PREFS_TO_SET=(
    "media.gmp-gmpopenh264.autoupdate"
    "media.gmp-gmpopenh264.enabled"
    "media.gmp-gmpopenh264.provider.enabled"
    "media.peerconnection.video.h264_enabled"
)

for PREF in "${PREFS_TO_SET[@]}"; do
    # 1. Delete any existing line for the preference
    sed -i "/^user_pref(\"$PREF\",/d" "$PREFS_FILE"
    # 2. Add the new preference line
    echo "user_pref(\"$PREF\", true);" >> "$PREFS_FILE"
done