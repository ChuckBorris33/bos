#!/bin/bash

set -euo pipefail

# Install RPMFusion non-free repository
dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm >&2

# Install steam and gamescope
dnf install -y steam gamescope >&2

# Enable SSH (best effort, may fail in container)
systemctl enable sshd.service >&2 2>/dev/null || true
