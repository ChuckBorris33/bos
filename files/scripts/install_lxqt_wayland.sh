#!/usr/bin/env bash

set -oue pipefail

dnf -y groupinstall lxqt
dnf -y install labwc lxqt-labwc-session lxqt-wayland-session
