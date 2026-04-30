#!/usr/bin/env bash
set -e
apt-get update
apt-get install -y tmux


echo "Generating SSH key for GitHub "

# Generate SSH key (non-interactive, overwrite-safe)
ssh-keygen -t ed25519 \
  -C "irsyad@smb" \
  -f /root/.ssh/id_ed25519 \
  -N "" \
  -q

# Start ssh-agent
eval "$(ssh-agent -s)"

# Add key to agent
ssh-add /root/.ssh/id_ed25519

echo ""
echo "SSH key generated and added to agent."
echo ""
echo "COPY THIS PUBLIC KEY INTO GITHUB → Settings → SSH Keys:"
echo "------------------------------------------------------------"
cat /root/.ssh/id_ed25519.pub
echo "------------------------------------------------------------"

git config --global user.email "irsyad@smb"
git config --global user.name "irsyad@smb"

curl -fsSL https://claude.ai/install.sh | bash

export TERM=xterm-256color
