#!/usr/bin/env bash

mkdir -p /var/log/bootc-hooks
echo "$(date '+%Y-%m-%d %H:%M:%S') - System boot script called" >> /var/log/bootc-hooks/log.txt
