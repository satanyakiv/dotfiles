#!/bin/bash
# Symlink dotfiles to home directory

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

ln -sf "$DOTFILES_DIR/.zshrc" ~/.zshrc
ln -sf "$DOTFILES_DIR/.gitconfig" ~/.gitconfig
ln -sf "$DOTFILES_DIR/.p10k.zsh" ~/.p10k.zsh
mkdir -p ~/.ssh
ln -sf "$DOTFILES_DIR/.ssh/config" ~/.ssh/config
ln -sfn "$DOTFILES_DIR/.claude" ~/.claude

echo "Dotfiles linked."

echo ""
echo "Don't forget to install:"
echo "  1. oh-my-zsh: sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
echo "  2. powerlevel10k: git clone https://github.com/romkatv/powerlevel10k \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k"
echo "  3. zsh-autosuggestions: git clone https://github.com/zsh-users/zsh-autosuggestions \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
echo "  4. zsh-syntax-highlighting: git clone https://github.com/zsh-users/zsh-syntax-highlighting \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
echo "  5. brew bundle --file=Brewfile.server"
