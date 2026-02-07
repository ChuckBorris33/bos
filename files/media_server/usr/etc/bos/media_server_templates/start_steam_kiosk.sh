#!/bin/bash
# Starts a Gamescope session with Steam in Big Picture mode on TTY1.

if test "$(tty)" != "/dev/tty1"; then
    exit 0
fi

gamescope -e -- /usr/bin/steam -bigpicture
