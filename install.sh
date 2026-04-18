#!/bin/bash
# Symlink dotfiles to home directory.
# Idempotent: safe to re-run. Existing non-symlink files get .bak.<timestamp>.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"

# Link one path from DOTFILES_DIR to $HOME, backing up any real file/dir already there.
# $1 = relative path under DOTFILES_DIR (equal to path under $HOME)
link() {
  local rel="$1"
  local src="$DOTFILES_DIR/$rel"
  local dst="$HOME/$rel"
  local dst_dir
  dst_dir="$(dirname "$dst")"
  mkdir -p "$dst_dir"

  # If dst is already the correct symlink — do nothing.
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return 0
  fi

  # Backup any existing real file or wrong symlink.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak.$TS"
    echo "  backed up: $dst -> $dst.bak.$TS"
  fi

  ln -s "$src" "$dst"
  echo "  linked:    $dst -> $src"
}

echo "== Linking shell/git configs =="
link ".zshrc"
link ".gitconfig"
link ".p10k.zsh"
mkdir -p "$HOME/.ssh"
link ".ssh/config"

echo "== Linking .claude per-item =="
# Runtime dirs (sessions, projects, plans, cache, etc.) stay local.
# We only link config-like items from $DOTFILES_DIR/.claude.
mkdir -p "$HOME/.claude"

# Remove any residual legacy symlinks.
if [ -L "$HOME/.claude" ]; then
  echo "  warning: \$HOME/.claude is a symlink (legacy). Converting to directory."
  target="$(readlink "$HOME/.claude")"
  rm "$HOME/.claude"
  mkdir -p "$HOME/.claude"
  echo "  was pointing to: $target (removed)"
fi
if [ -L "$HOME/.claude/.claude" ]; then
  echo "  removing residual: \$HOME/.claude/.claude"
  rm "$HOME/.claude/.claude"
fi

# Iterate over every item in $DOTFILES_DIR/.claude and link it.
# This way any new config file/dir we add to dotfiles gets linked automatically.
shopt -s dotglob nullglob
for src in "$DOTFILES_DIR/.claude"/*; do
  name="$(basename "$src")"
  # Skip local-only files that shouldn't be synced.
  case "$name" in
    .DS_Store|worktrees) continue ;;
  esac
  link ".claude/$name"
done
shopt -u dotglob nullglob

echo ""
echo "== Done =="
echo ""
echo "If this is a fresh machine, also install:"
echo "  1. oh-my-zsh: sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
echo "  2. powerlevel10k: git clone https://github.com/romkatv/powerlevel10k \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k"
echo "  3. zsh-autosuggestions: git clone https://github.com/zsh-users/zsh-autosuggestions \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
echo "  4. zsh-syntax-highlighting: git clone https://github.com/zsh-users/zsh-syntax-highlighting \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
echo "  5. brew bundle --file=Brewfile.server"
