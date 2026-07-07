#!/usr/bin/env bash
set -e
apt-get update
apt-get install -y tmux

export TERM=xterm-256color

cat > ~/.tmux.conf <<'EOF'
set -g mouse on
set -g history-limit 50000
EOF

curl -fsSL https://claude.ai/install.sh | bash

