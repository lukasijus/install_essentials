#!/usr/bin/env bash
set -euo pipefail

log() {
  printf "\n\033[1;34m==>\033[0m %s\n" "$*"
}

warn() {
  printf "\n\033[1;33mWARN:\033[0m %s\n" "$*" >&2
}

have() {
  command -v "$1" >/dev/null 2>&1
}

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
backup_stamp="$(date +%Y%m%d-%H%M%S)"

sudo_cmd=()
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  sudo_cmd=(sudo)
fi

append_once() {
  local line="$1"
  local file="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  grep -qxF "$line" "$file" 2>/dev/null || printf '%s\n' "$line" >>"$file"
}

backup_and_install() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    local backup="${dst}.bak.${backup_stamp}"
    cp -a "$dst" "$backup"
    log "Backed up $dst to $backup"
  fi
  cp -f "$src" "$dst"
}

install_packages() {
  log "Installing base packages"
  if have apt-get; then
    "${sudo_cmd[@]}" apt-get update
    "${sudo_cmd[@]}" apt-get install -y \
      bash bat ca-certificates build-essential curl fd-find fontconfig git gzip \
      python3 python3-pip python3-venv ripgrep tar tmux unzip wget wl-clipboard \
      xclip xsel

    if ! have fd && have fdfind; then
      "${sudo_cmd[@]}" ln -sf "$(command -v fdfind)" /usr/local/bin/fd
    fi
  elif have dnf; then
    "${sudo_cmd[@]}" dnf install -y \
      bash bat ca-certificates curl fd-find fontconfig git gcc gcc-c++ make \
      python3 python3-pip ripgrep tar tmux unzip wget xclip
  elif have yum; then
    "${sudo_cmd[@]}" yum install -y \
      bash bat ca-certificates curl fontconfig git gcc gcc-c++ make python3 \
      python3-pip ripgrep tar tmux unzip wget
  else
    warn "No supported package manager found. Install base packages manually."
  fi
}

install_uv() {
  log "Installing uv"
  if ! have uv; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
  export PATH="$HOME/.local/bin:$PATH"
}

install_node() {
  log "Installing Node.js LTS with nvm"
  export NVM_DIR="$HOME/.nvm"
  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  fi
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default 'lts/*'
  npm install -g @fsouza/prettierd @openai/codex prettier tree-sitter-cli
}

install_neovim() {
  log "Installing Neovim"
  local arch asset tmp
  arch="$(uname -m)"
  case "$arch" in
    x86_64 | amd64) asset="nvim-linux-x86_64.tar.gz" ;;
    aarch64 | arm64) asset="nvim-linux-arm64.tar.gz" ;;
    *)
      warn "No Neovim release tarball path configured for $arch. Falling back to OS package."
      if have apt-get; then
        "${sudo_cmd[@]}" apt-get install -y neovim
      elif have dnf; then
        "${sudo_cmd[@]}" dnf install -y neovim
      elif have yum; then
        "${sudo_cmd[@]}" yum install -y neovim
      fi
      return
      ;;
  esac

  tmp="$(mktemp -d)"
  curl -L -o "$tmp/$asset" "https://github.com/neovim/neovim/releases/latest/download/$asset"
  "${sudo_cmd[@]}" rm -rf "/opt/${asset%.tar.gz}"
  "${sudo_cmd[@]}" tar -C /opt -xzf "$tmp/$asset"
  rm -rf "$tmp"
  append_once 'export PATH="/opt/nvim-linux-x86_64/bin:/opt/nvim-linux-arm64/bin:$PATH"' "$HOME/.profile"
  export PATH="/opt/nvim-linux-x86_64/bin:/opt/nvim-linux-arm64/bin:$PATH"
}

install_fonts() {
  log "Installing JetBrainsMono Nerd Font"
  local tmp font_dir
  tmp="$(mktemp -d)"
  font_dir="$HOME/.local/share/fonts"
  mkdir -p "$font_dir"
  curl -L -o "$tmp/JetBrainsMono.zip" \
    https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
  unzip -o "$tmp/JetBrainsMono.zip" -d "$font_dir"
  fc-cache -fv >/dev/null
  rm -rf "$tmp"
}

install_formatters() {
  log "Installing editor formatters"
  uv tool install black || true
  if have apt-get; then
    "${sudo_cmd[@]}" apt-get install -y stylua || true
  elif have dnf; then
    "${sudo_cmd[@]}" dnf install -y stylua || true
  fi
  if ! have stylua && have cargo; then
    cargo install stylua || true
  fi
}

install_dotfiles() {
  log "Installing dotfiles and helper scripts"
  backup_and_install "$repo_dir/dotfiles/bashrc" "$HOME/.bashrc"
  backup_and_install "$repo_dir/dotfiles/codex/config.toml" "$HOME/.codex/config.toml"
  backup_and_install "$repo_dir/dotfiles/inputrc" "$HOME/.inputrc"
  backup_and_install "$repo_dir/dotfiles/tmux.conf" "$HOME/.tmux.conf"
  backup_and_install "$repo_dir/dotfiles/nvim/init.lua" "$HOME/.config/nvim/init.lua"

  mkdir -p "$HOME/bin"
  backup_and_install "$repo_dir/bin/config_nvim" "$HOME/bin/config_nvim"
  backup_and_install "$repo_dir/bin/nvim_src" "$HOME/bin/nvim_src"
  chmod +x "$HOME/bin/config_nvim" "$HOME/bin/nvim_src"

  append_once 'export PATH="$HOME/bin:$HOME/.local/bin:$PATH"' "$HOME/.profile"
}

bootstrap_neovim() {
  if have nvim; then
    log "Bootstrapping Neovim plugins"
    nvim --headless "+Lazy! sync" +qa || true
    nvim --headless "+MasonInstall pyright typescript-language-server vue-language-server" +qa || true
    nvim --headless "+TSUpdate" +qa || true
  else
    warn "nvim is not available on PATH yet; open a new shell and run :Lazy sync."
  fi
}

main() {
  install_packages
  install_uv
  install_node
  install_neovim
  install_fonts
  install_formatters
  install_dotfiles
  bootstrap_neovim
  log "Done. Open a new terminal or run: source ~/.bashrc"
}

main "$@"
