#!/usr/bin/env bash

mkdir -p "$HOME/.local/share/bootc-hooks"
echo "$(date '+%Y-%m-%d %H:%M:%S') - User boot script called" >> "$HOME/.local/share/bootc-hooks/log.txt"
