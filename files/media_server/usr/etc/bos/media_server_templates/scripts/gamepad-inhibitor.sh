#!/bin/bash
# Monitors joystick/gamepad input and inhibits idle/sleep when active
# Reads directly from /dev/input/event* devices - any output means activity

set -e

# Configuration
IDLE_TIMEOUT_MS=30000  # Release inhibit after 30 seconds of no input
INHIBIT_WHAT="idle:sleep:handle-lid-switch"
INHIBIT_WHO="gamepad-inhibitor"
INHIBIT_REASON="Game controller active"
POLL_INTERVAL=5        # Check for new devices every 5 seconds

# Cache for joystick detection
JOYSTICK_CACHE_FILE="/tmp/gamepad_inhibitor_joysticks"

# Find all joystick/gamepad input devices
find_joysticks() {
    local joysticks=""
    for device in /sys/class/input/event*; do
        if [ -f "$device/device/name" ]; then
            local name
            name=$(cat "$device/device/name" 2>/dev/null || true)
            # Match common joystick/gamepad patterns
            if echo "$name" | grep -qiE "(joystick|gamepad|controller|xbox|playstation|dualsense|dualshock|nintendo|steam|8bitdo|iinet|wireless|bluetooth|usb.*game)"; then
                joysticks="$joysticks /dev/input/$(basename "$device")"
            fi
        fi
    done
    # Cache for hotplug detection
    echo "$joysticks" > "$JOYSTICK_CACHE_FILE"
    echo "$joysticks"
}

# Check if display is off and wake it up
wake_display() {
    if command -v swaymsg >/dev/null 2>&1; then
        local dpms_status
        dpms_status=$(swaymsg -t get_outputs 2>/dev/null | grep -o '"power":\s*\([^,]*\)' | head -1 | grep -o 'on\|off' || true)
        if [ "$dpms_status" = "off" ]; then
            echo "Display is off, turning on..."
            swaymsg "output * dpms on" 2>/dev/null || true
        fi
    elif command -v xset >/dev/null 2>&1; then
        xset dpms force on 2>/dev/null || true
    fi
}

# Monitor a single device - any output means activity
monitor_device() {
    local device="$1"
    local fifo="$2"
    
    while true; do
        if [ -r "$device" ]; then
            # Read directly from device - any data means activity
            # Using dd for better control, reading in chunks
            dd if="$device" bs=24 count=1 2>/dev/null | head -c 1 >/dev/null && {
                echo "ACTIVE" > "$fifo" 2>/dev/null || true
            }
        fi
        # Small delay to prevent busy-looping
        sleep 0.01
    done
}

# Check for new devices and start monitoring them
check_new_devices() {
    local fifo="$1"
    local current_joysticks monitored
    
    current_joysticks=$(find_joysticks)
    
    # Read cached list
    if [ -f "$JOYSTICK_CACHE_FILE" ]; then
        monitored=$(cat "$JOYSTICK_CACHE_FILE")
    else
        monitored=""
    fi
    
    # Check for new devices
    for js in $current_joysticks; do
        if ! echo "$monitored" | grep -q "$js"; then
            echo "New joystick detected: $js"
            monitor_device "$js" "$fifo" &
        fi
    done
}

# Main function
main() {
    echo "Starting gamepad inhibitor (no evtest required)..."
    
    # Create a FIFO for signaling activity
    FIFO_DIR=$(mktemp -d)
    FIFO="$FIFO_DIR/activity"
    mkfifo "$FIFO"
    
    # Cleanup function
    cleanup() {
        echo "Cleaning up..."
        rm -rf "$FIFO_DIR"
        rm -f "$JOYSTICK_CACHE_FILE"
        # Kill all background jobs
        jobs -p | xargs -r kill 2>/dev/null || true
        exit 0
    }
    trap cleanup EXIT INT TERM
    
    # Find and monitor all joystick devices
    JOYSTICKS=$(find_joysticks)
    
    if [ -z "$JOYSTICKS" ]; then
        echo "No joysticks found, will check periodically..."
    else
        echo "Found joysticks:$JOYSTICKS"
        
        # Start monitoring each joystick in background
        for js in $JOYSTICKS; do
            echo "Monitoring: $js"
            monitor_device "$js" "$FIFO" &
        done
    fi
    
    # Main inhibit loop
    local last_activity inhibit_pid inhibiting
    last_activity=$(date +%s%3N)
    inhibiting=false
    inhibit_pid=""
    
    # Use a background process to continuously read from FIFO
    exec 3<>"$FIFO"
    
    while true; do
        local current_time elapsed
        current_time=$(date +%s%3N)
        elapsed=$((current_time - last_activity))
        
        # Check for activity from any monitor (non-blocking read)
        local line
        if IFS= read -t 0.1 -r line <&3 2>/dev/null; then
            if [ "$line" = "ACTIVE" ]; then
                last_activity=$current_time
                wake_display
            fi
        fi
        
        # Start or stop inhibit based on activity
        if [ "$elapsed" -lt "$IDLE_TIMEOUT_MS" ]; then
            if [ "$inhibiting" = false ]; then
                echo "Controller active - inhibiting sleep/idle"
                # Start systemd-inhibit in background
                systemd-inhibit \
                    --what="$INHIBIT_WHAT" \
                    --who="$INHIBIT_WHO" \
                    --why="$INHIBIT_REASON" \
                    --mode=block \
                    sleep infinity &
                inhibit_pid=$!
                inhibiting=true
            fi
        else
            if [ "$inhibiting" = true ]; then
                echo "Controller idle - releasing inhibit"
                if [ -n "$inhibit_pid" ]; then
                    kill "$inhibit_pid" 2>/dev/null || true
                    wait "$inhibit_pid" 2>/dev/null || true
                fi
                inhibiting=false
                inhibit_pid=""
            fi
        fi
        
        # Check for new devices periodically
        if [ $((elapsed % (POLL_INTERVAL * 1000))) -lt 100 ]; then
            check_new_devices "$FIFO"
        fi
        
        sleep 0.1
    done
}

# Run main function
main
