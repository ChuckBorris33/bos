!# /usr/bin/env bash

set -euo pipefail

yadm clone --no-bootstrap git@github.com:ChuckBorris33/dotfiles.git
yadm reset --hard origin/main
