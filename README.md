# install_essentials

Small public bootstrap repo for a fresh Linux development machine.

It installs the stack I expect on Ubuntu/Debian desktops, NVIDIA Jetson Ubuntu
images, and ordinary cloud Linux machines:

- Bash defaults and a compact git-aware prompt
- tmux with vi-style copy mode
- Neovim plus the current Lua config
- Node.js LTS via `nvm`
- OpenAI Codex CLI via the global `@openai/codex` npm package
- Python tooling via `uv`
- common CLI tools: `git`, `gh`, `curl`, `ripgrep`, `fd`, compilers, clipboard helpers
- formatters used by Neovim: `black`, `stylua`, `shfmt`, `prettierd`

This repo intentionally does not include Aider wrappers, `.env` files, API keys,
Shopify credentials, project-specific service files, or private path shortcuts
from `myscripts`. It also does not include private Codex auth, history, session
state, logs, caches, or machine IDs from `~/.codex`.

## Install

```bash
git clone https://github.com/<you>/install_essentials.git
cd install_essentials
./install.sh
```

The script is idempotent enough for normal re-runs. Existing dotfiles are backed
up once with a timestamp before the managed files are installed.

## What Gets Managed

- `~/.bashrc`
- `~/.codex/config.toml`
- `~/.inputrc`
- `~/.tmux.conf`
- `~/.config/nvim/init.lua`
- `~/bin/config_nvim`
- `~/bin/nvim_src`
- `~/bin/tmux_clipboard_doctor`

## Notes

- Neovim is installed from the official release tarball on `x86_64` and `arm64`.
  Other architectures fall back to the OS package manager.
- Nerd Font icons in Neovim require the terminal profile to use a Nerd Font.
  On Ubuntu GNOME Terminal, `install.sh` sets the default profile to
  `JetBrainsMono Nerd Font 12`. In other terminals, select
  `JetBrainsMono Nerd Font` manually if icons appear as boxes.
- tmux copy mode sends yanks to the desktop clipboard when `wl-copy`, `xclip`,
  or `xsel` is available. Use `Ctrl-b [` then `yy` or `Y` to copy the current
  line without leaving copy mode, or `Ctrl-b [` then `v`, move, and `y` to copy
  a selection. New interactive shells refresh tmux's `DISPLAY`,
  `WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR`, and `SSH_AUTH_SOCK` values so an older
  tmux server can still reach the desktop clipboard. Run
  `tmux_clipboard_doctor` if browser paste does not work after install.
- Node is installed with `nvm` because that works well across x86 cloud machines
  and arm64 Jetson boards.
- Codex auth is intentionally per-machine. After install, run `codex login`.
- Secrets belong in private shell files or a password manager, not this repo.
