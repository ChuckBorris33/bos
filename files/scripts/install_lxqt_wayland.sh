#!/usr/bin/env bash

set -oue pipefail
dnf5 -y group install "lxqt-desktop-environment"
dnf -y install labwc lxqt-labwc-session lxqt-wayland-session
