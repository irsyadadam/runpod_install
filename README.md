# RunPod CLI setup

Install Codex, Claude Code, Git, and tmux on an Ubuntu/Debian pod:

```bash
git clone https://github.com/irsyadadam/runpod_install.git
cd runpod_install
bash install_gh_claude_kitty.sh
export PATH="$HOME/.local/bin:$PATH"
```

The script retains its original filename. It installs Node.js 22 through
NodeSource when Node.js 22+ and npm are not already available. Codex uses the
official npm package; Claude Code uses its native installer. Both commands are
installed under `~/.local/bin`, with PATH added to `.bashrc` and `.profile`.

Run as root on a typical RunPod image, or as a user with sudo access. When
launched through sudo, the CLIs install for the original user. Rerunning skips
working CLI installations and preserves existing tmux settings.

Start either CLI and follow its sign-in prompts:

```bash
codex
claude
```

Installation does not sign you in. For Codex on a remote pod, you can also use
`codex login --device-auth`. No API keys or login credentials belong in this repo.

Upstream installation instructions:

- [Codex](https://developers.openai.com/cookbook/examples/codex/using_goals_in_codex)
- [Claude Code](https://code.claude.com/docs/en/setup)
- [NodeSource](https://github.com/nodesource/distributions/blob/master/DEV_README.md)
