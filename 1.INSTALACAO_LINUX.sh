#!/usr/bin/env bash
set -eo pipefail

# Skip if Node.js is already installed
if command -v node >/dev/null 2>&1; then
  echo "Node.js $(node -v) is already installed."
  exit 0
fi

# macOS with Homebrew: the simplest route
if [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
  echo "Installing Node.js LTS with Homebrew..."
  brew install node
  echo "Installed: node $(node -v), npm $(npm -v)"
  exit 0
fi

# Linux or macOS without Homebrew: use nvm
command -v curl >/dev/null 2>&1 || { echo "curl is required."; exit 1; }

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  NVM_VERSION="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
    | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)"
  NVM_VERSION="${NVM_VERSION:-v0.40.3}"
  echo "Installing nvm ${NVM_VERSION}..."
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi

# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

echo "Installing Node.js LTS..."
nvm install --lts
nvm alias default 'lts/*'

echo "Installed: node $(node -v), npm $(npm -v)"
echo "Open a new terminal (or run: source ~/.bashrc) to pick up the PATH change."
