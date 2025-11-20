#!/usr/bin/env bash

mkdir -p ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
yadm clone --no-bootstrap git@github.com:ChuckBorris33/dotfiles.git
yadm reset --hard origin/main
yadm bootstrap
