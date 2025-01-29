#!/bin/bash

set -e  # Exit immediately if a command fails

echo -e "\e[1;32mUpdating package lists...\e[0m"
sudo apt update

echo -e "\e[1;32mInstalling dependencies...\e[0m"
sudo apt install -y $(echo "zsh git curl wget unzip fzf direnv htop ripgrep bat tesseract-ocr python3 python3-pip python3-venv build-essential jq cargo fonts-powerline" | tr ' ' '\n' | xargs)

# Install Rust if not installed
if ! command -v rustc &>/dev/null; then
    echo -e "\e[1;34mInstalling Rust...\e[0m"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # Ensure Rust is available in Zsh
    source "$HOME/.cargo/env"
fi

# Install Oh My Zsh if not installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "\e[1;34mInstalling Oh My Zsh...\e[0m"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Powerlevel10k theme
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
wait  # Wait for all background jobs to finish

# Install exa and dust via Cargo (since they are not in Ubuntu 20.04 repos)
if ! command -v exa &>/dev/null; then
    echo -e "\e[1;34mInstalling exa...\e[0m"
    cargo install exa
fi

if ! command -v dust &>/dev/null; then
    echo -e "\e[1;34mInstalling dust...\e[0m"
    cargo install du-dust
fi

# Ensure ~/.cargo/bin is in the PATH
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.zshrc"

# Create .zshrc with the provided configuration
cat > "$HOME/.zshrc" << 'EOF'
# Enable Powerlevel10k instant prompt
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

# Source Nix
source ~/.nix-profile/etc/profile.d/nix.sh

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

# Custom functions
source ~/.package_management.zsh

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

# Install Rust if not installed
command -v rustc &>/dev/null || { echo -e "\e[1;34mInstalling Rust...\e[0m"; curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; source "$HOME/.cargo/env"; }

# Install rust-analyzer and rls
rustup component add rust-analyzer rls

# Ensure Rust is available in Zsh
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.zshrc"

echo -e "\e[1;32mSystem updated! Rust and Zsh are ready.\e[0m"
