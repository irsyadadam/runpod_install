#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "ERROR: command failed at line ${LINENO}: ${BASH_COMMAND}" >&2' ERR

echo "Starting machine setup..."

# -------------------------------------------------------------------
# 1. Confirm this is a Debian/Ubuntu-style machine
# -------------------------------------------------------------------
if ! command -v apt-get >/dev/null 2>&1; then
    echo "ERROR: This script requires Debian or Ubuntu with apt-get." >&2
    exit 1
fi

# -------------------------------------------------------------------
# 2. Determine whether sudo is needed
# -------------------------------------------------------------------
if [[ "$(id -u)" -eq 0 ]]; then
    SUDO=()
else
    if ! command -v sudo >/dev/null 2>&1; then
        echo "ERROR: Run this script as root, or install sudo first." >&2
        exit 1
    fi

    SUDO=(sudo)
fi

# Install for the original user when the script was launched with sudo.
TARGET_USER="${SUDO_USER:-$(id -un)}"
TARGET_GROUP="$(id -gn "$TARGET_USER")"

if command -v getent >/dev/null 2>&1; then
    TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
else
    TARGET_HOME="${HOME}"
fi

if [[ -z "$TARGET_HOME" ]]; then
    echo "ERROR: Could not determine home directory for $TARGET_USER." >&2
    exit 1
fi

echo "Installing for user: $TARGET_USER"
echo "Home directory: $TARGET_HOME"

# Run a command as the target user.
run_as_target() {
    if [[ "$(id -un)" == "$TARGET_USER" ]]; then
        HOME="$TARGET_HOME" "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo -H -u "$TARGET_USER" env HOME="$TARGET_HOME" "$@"
    elif command -v runuser >/dev/null 2>&1; then
        runuser -u "$TARGET_USER" -- env HOME="$TARGET_HOME" "$@"
    else
        echo "ERROR: Cannot run a command as $TARGET_USER." >&2
        exit 1
    fi
}

# Add a line to a user configuration file only if it is not present.
append_line() {
    local file="$1"
    local line="$2"

    "${SUDO[@]}" touch "$file"

    if ! "${SUDO[@]}" grep -qxF "$line" "$file"; then
        printf '%s\n' "$line" |
            "${SUDO[@]}" tee -a "$file" >/dev/null
    fi

    "${SUDO[@]}" chown "$TARGET_USER:$TARGET_GROUP" "$file"
}

# -------------------------------------------------------------------
# 3. Install system packages
# -------------------------------------------------------------------
echo "Updating apt repositories..."

"${SUDO[@]}" env DEBIAN_FRONTEND=noninteractive \
    apt-get update

echo "Installing required packages..."

"${SUDO[@]}" env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        tmux

# -------------------------------------------------------------------
# 4. Configure tmux
# -------------------------------------------------------------------
echo "Writing tmux configuration..."

TMUX_TEMP="$(mktemp)"

cat > "$TMUX_TEMP" <<'EOF'
set -g mouse on
set -g history-limit 50000
set -g default-terminal "tmux-256color"
set -as terminal-features ",xterm-256color:RGB"
EOF

"${SUDO[@]}" install \
    -o "$TARGET_USER" \
    -g "$TARGET_GROUP" \
    -m 0644 \
    "$TMUX_TEMP" \
    "$TARGET_HOME/.tmux.conf"

rm -f "$TMUX_TEMP"

# -------------------------------------------------------------------
# 5. Persist terminal and PATH configuration
# -------------------------------------------------------------------
echo "Configuring shell environment..."

append_line "$TARGET_HOME/.bashrc" \
    'export TERM=xterm-256color'

append_line "$TARGET_HOME/.bashrc" \
    'export PATH="$HOME/.local/bin:$PATH"'

append_line "$TARGET_HOME/.profile" \
    'export PATH="$HOME/.local/bin:$PATH"'

# Make the values available to the remainder of this script.
export TERM=xterm-256color
export PATH="$TARGET_HOME/.local/bin:$PATH"

# -------------------------------------------------------------------
# 6. Install Claude Code
# -------------------------------------------------------------------
CLAUDE_BIN="$TARGET_HOME/.local/bin/claude"

if [[ -x "$CLAUDE_BIN" ]]; then
    echo "Claude Code is already installed."
else
    echo "Installing Claude Code..."

    run_as_target bash -c '
        set -o pipefail
        curl -fsSL https://claude.ai/install.sh | bash
    '
fi

# -------------------------------------------------------------------
# 7. Install OpenAI Codex CLI
# -------------------------------------------------------------------
CODEX_BIN="$TARGET_HOME/.local/bin/codex"

if [[ -x "$CODEX_BIN" ]]; then
    echo "Codex CLI is already installed."
else
    echo "Installing Codex CLI..."

    run_as_target bash -c '
        set -o pipefail
        curl -fsSL https://chatgpt.com/codex/install.sh | sh
    '
fi

# -------------------------------------------------------------------
# 8. Verify installation
# -------------------------------------------------------------------
echo
echo "Verifying installations..."

tmux -V

if [[ ! -x "$CLAUDE_BIN" ]]; then
    echo "ERROR: Claude installation completed, but $CLAUDE_BIN was not found." >&2
    exit 1
fi

run_as_target "$CLAUDE_BIN" --version

if [[ ! -x "$CODEX_BIN" ]]; then
    echo "ERROR: Codex installation completed, but $CODEX_BIN was not found." >&2
    exit 1
fi

run_as_target "$CODEX_BIN" --version

echo
echo "Setup completed successfully."
echo
echo "Open a new terminal, or run:"
echo
echo "    source \"$TARGET_HOME/.bashrc\""
echo
echo "Then start either coding agent with:"
echo
echo "    claude"
echo "    codex"
