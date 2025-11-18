#!/usr/bin/env bash

mkdir -p "$HOME/.local/share/bootc-hooks"
echo "$(date '+%Y-%m-%d %H:%M:%S') - User update script called" >> "$HOME/.local/share/bootc-hooks/log.txt"
