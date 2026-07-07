#!/usr/bin/env bash
set -e
apt-get update
apt-get install -y tmux

export TERM=xterm-256color

set -g mouse on
tmux source-file ~/.tmux.conf

curl -fsSL https://claude.ai/install.sh | bash

