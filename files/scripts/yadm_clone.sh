#!/usr/bin/env bash

yadm clone --no-bootstrap git@github.com:ChuckBorris33/dotfiles.git && yadm reset --hard origin/main
yadm bootstrap
