# install_essentials

Small public bootstrap repo for a fresh Linux development machine.

It installs the stack I expect on Ubuntu/Debian desktops, NVIDIA Jetson Ubuntu
images, and ordinary cloud Linux machines:

- Bash defaults and a compact git-aware prompt
- tmux with vi-style copy mode
- Neovim plus the current Lua config
- Node.js LTS via `nvm`
- Python tooling via `uv`
- common CLI tools: `git`, `curl`, `ripgrep`, `fd`, compilers, clipboard helpers
- formatters used by Neovim: `black`, `stylua`, `prettierd`

This repo intentionally does not include Aider wrappers, `.env` files, API keys,
Shopify credentials, project-specific service files, or private path shortcuts
from `myscripts`.

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
- `~/.tmux.conf`
- `~/.config/nvim/init.lua`
- `~/bin/config_nvim`
- `~/bin/nvim_src`

## Notes

- Neovim is installed from the official release tarball on `x86_64` and `arm64`.
  Other architectures fall back to the OS package manager.
- Node is installed with `nvm` because that works well across x86 cloud machines
  and arm64 Jetson boards.
- Secrets belong in private shell files or a password manager, not this repo.
