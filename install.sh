#!/bin/bash

set -e  # Exit immediately if a command fails

echo -e "\e[1;32mUpdating package lists...\e[0m"
sudo apt update -y

# Check if curl is installed
if ! command -v curl &>/dev/null; then
    echo -e "\e[1;34mInstalling curl...\e[0m"
    sudo apt install -y curl
fi

# Check if direnv is installed
if ! command -v direnv &>/dev/null; then
    echo -e "\e[1;34mInstalling direnv...\e[0m"
    sudo apt install -y direnv
fi

# Check if Nix is installed
if ! command -v nix-env &>/dev/null; then
    echo -e "\e[1;34mInstalling Nix...\e[0m"
    
    # Install Nix using the official installation script
    curl -L https://nixos.org/nix/install | sh

    # Add Nix to the system path for the current user
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    
    echo -e "\e[1;32mNix installation complete!\e[0m"
else
    echo -e "\e[1;32mNix is already installed.\e[0m"
fi

# Install Rust via Nix if not installed
if ! command -v rustc &>/dev/null; then
    echo -e "\e[1;34mInstalling Rust via Nix...\e[0m"
    nix-env -iA nixpkgs.rust
    echo -e "\e[1;32mRust installation complete!\e[0m"
else
    echo -e "\e[1;32mRust is already installed.\e[0m"
fi

# Ensure Rust is available in Zsh
source "$HOME/.cargo/env"

# Install system dependencies via apt in parallel
echo -e "\e[1;32mInstalling system dependencies...\e[0m"
sudo apt install -y \
    zsh git curl wget unzip fzf direnv htop ripgrep bat tesseract-ocr python3 python3-pip python3-venv build-essential jq cargo fonts-powerline \
    &

# Install Oh My Zsh in the background
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "\e[1;34mInstalling Oh My Zsh...\e[0m"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended &
fi

# Install Powerlevel10k theme in the background
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    echo -e "\e[1;34mInstalling Powerlevel10k...\e[0m"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" &
fi

# Install Zsh plugins in parallel
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
PLUGINS=(
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-completions"
    "zsh-users/zsh-history-substring-search"
    "lukechilds/zsh-nvm"
    "ptavares/zsh-direnv"
)

for repo in "${PLUGINS[@]}"; do
    PLUGIN_NAME=$(basename "$repo")
    if [ ! -d "$ZSH_CUSTOM/plugins/$PLUGIN_NAME" ]; then
        echo -e "\e[1;34mInstalling $PLUGIN_NAME...\e[0m"
        git clone --depth=1 "https://github.com/$repo.git" "$ZSH_CUSTOM/plugins/$PLUGIN_NAME" &
    fi
done

# Install exa and dust via Nix if they are not installed
for pkg in exa dust; do
    if ! command -v $pkg &>/dev/null; then
        echo -e "\e[1;34mInstalling $pkg via Nix...\e[0m"
        nix-env -iA nixpkgs.$pkg &
    fi
done

wait  # Wait for all background jobs to finish

# Ensure ~/.cargo/bin is in the PATH
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.zshrc"

# Create .zshrc with the provided configuration
cat > "$HOME/.zshrc" << 'EOF'
# Enable Powerlevel10k instant prompt
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set the theme to Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# Enable case-insensitive and hyphen-insensitive completion
zstyle ':completion:*' case sensitive false
zstyle ':completion:*' hyphen insensitive true

# Auto-update settings
zstyle ':omz:update' mode reminder
zstyle ':omz:update' frequency 13

# Enable command auto-correction
ENABLE_CORRECTION="true"

# Display red dots while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Disable marking untracked files under VCS as dirty
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Set history timestamp format
HIST_STAMPS="dd/mm/yyyy"

# Increase history size and save history across sessions
HISTSIZE=20000
SAVEHIST=20000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt APPEND_HISTORY

# Enhance command search and navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB

# Plugins to load
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  zsh-history-substring-search
  zsh-nvm
  fzf
  direnv
  colored-man-pages
  web-search
  copyfile
  z
  git-prompt
)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Load FZF
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# User configuration
export LANG=en_US.UTF-8
export EDITOR='nvim'

# Enhanced and useful aliases
alias ls="exa --icons"
alias ll="exa -alF --icons"
alias la="exa -A --icons"
alias l="exa -CF --icons"
alias cat="bat --paging=never"
alias man="bat -pp --paging=always --pager='less -R'"
alias grep="rg"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias gs="git status"
alias gc="git commit -m"
alias gp="git push"
alias gl="git pull"
alias gpom="git push origin master"
alias c="clear"
alias h="history"
alias d="dust"
alias t="htop"
alias reload="source ~/.zshrc"

# Configure Powerlevel10k prompt if not already set
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Load direnv integration
eval "$(direnv hook zsh)"

export TESSDATA_PREFIX=/usr/share/

export PATH=/home/kaiden/.local/bin:$PATH
EOF

# Set Zsh as the default shell
if [[ "$SHELL" != "$(which zsh)" ]]; then
    echo -e "\e[1;34mChanging default shell to Zsh...\e[0m"
    sudo chsh -s "$(which zsh)" "$USER"
fi

echo -e "\e[1;32mInstallation complete! Restart your terminal or run 'zsh' to start using it.\e[0m"

# Install rust-analyzer and rls if necessary
rustup component add rust-analyzer rls

echo -e "\e[1;32mSystem updated! Rust and Zsh are ready.\e[0m"
