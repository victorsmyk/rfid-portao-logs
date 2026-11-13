#!/usr/bin/env bash
# Node.js LTS installer for macOS and Linux
# Usage: ./install.sh          (skips Node.js if already installed)
#        ./install.sh --force  (reinstalls Node.js)

# Run from the script's own folder so npm finds package.json
cd "$(dirname "$0")" || exit 1

have() { command -v "$1" >/dev/null 2>&1; }

pause_exit() {
  echo
  read -r -p "Press Enter to close..." _
  exit "${1:-1}"
}

# Use sudo only when needed and available
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  have sudo && SUDO="sudo"
fi

# ---------------------------------------------------------------
# Install methods
# ---------------------------------------------------------------
install_with_nvm() {
  echo "Installing Node.js LTS with nvm (no admin rights needed)..."
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    if have curl; then
      curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash || return 1
    elif have wget; then
      wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash || return 1
    else
      echo "Neither curl nor wget found."
      return 1
    fi
  fi
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh" || return 1
  nvm install --lts && nvm use --lts
}

install_macos() {
  if have brew; then
    echo "Installing Node.js LTS with Homebrew..."
    brew install node@22 && brew link --overwrite --force node@22 && return 0
    echo "Homebrew failed, trying nvm..."
  fi
  install_with_nvm
}

install_linux() {
  if have apt-get && have curl; then
    echo "Installing Node.js LTS with apt (NodeSource)..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO -E bash - \
      && $SUDO apt-get install -y nodejs && return 0
  elif have dnf && have curl; then
    echo "Installing Node.js LTS with dnf (NodeSource)..."
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | $SUDO bash - \
      && $SUDO dnf install -y nodejs && return 0
  elif have yum && have curl; then
    echo "Installing Node.js LTS with yum (NodeSource)..."
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | $SUDO bash - \
      && $SUDO yum install -y nodejs && return 0
  elif have pacman; then
    echo "Installing Node.js with pacman..."
    $SUDO pacman -Sy --noconfirm nodejs npm && return 0
  fi
  echo "Package manager method unavailable or failed, trying nvm..."
  install_with_nvm
}

# ---------------------------------------------------------------
# Node.js
# ---------------------------------------------------------------
if [ "${1:-}" != "--force" ] && have node; then
  echo "Node.js $(node -v) ja esta instalado."
else
  case "$(uname -s)" in
    Darwin) install_macos ;;
    Linux)  install_linux ;;
    *)
      echo "Sistema nao suportado: $(uname -s)"
      pause_exit 1
      ;;
  esac

  if [ $? -ne 0 ]; then
    echo "Falha ao instalar o Node.js."
    pause_exit 1
  fi

  # Make sure the current session sees the new install
  hash -r
  [ -d "/opt/homebrew/opt/node@22/bin" ] && export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
  [ -d "/usr/local/opt/node@22/bin" ]    && export PATH="/usr/local/opt/node@22/bin:$PATH"
fi

# ---------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------
if ! have npm; then
  echo "npm nao encontrado. Feche o terminal e execute o script novamente."
  pause_exit 1
fi

if [ ! -f "package.json" ]; then
  echo "package.json nao encontrado em \"$(pwd)\"."
  pause_exit 1
fi

echo
echo "Instalando dependencias..."
if ! npm install --omit=dev; then
  echo "Falha ao instalar as dependencias."
  pause_exit 1
fi

if [ ! -f "app.js" ]; then
  echo "app.js nao encontrado em \"$(pwd)\"."
  pause_exit 1
fi

echo
echo "Node.js e as dependencias foram instaladas com sucesso."
echo "Iniciando: node app.js"
echo
node app.js
pause_exit $?