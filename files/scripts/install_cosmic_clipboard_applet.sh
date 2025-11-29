#!/usr/bin/env bash

set -oue pipefail

git clone https://github.com/cosmic-utils/clipboard-manager.git
cd clipboard-manager
dnf -y install libxkbcommon-devel cargo
just build-release && sudo just install
dnf -y remove libxkbcommon-devel cargo
