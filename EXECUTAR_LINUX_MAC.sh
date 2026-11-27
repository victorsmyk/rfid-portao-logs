#!/usr/bin/env bash

cd "$(dirname "$0")" || exit 1

NODE_FORMULA="node@22"

have() { command -v "$1" >/dev/null 2>&1; }

pause_exit() {
  echo
  if [ -t 0 ]; then
    read -r -p "Pressione Enter para fechar..." _
  fi
  exit "${1:-1}"
}

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif have sudo; then
    sudo -E "$@"
  else
    "$@"
  fi
}

install_with_nvm() {
  echo "Instalando Node.js LTS com nvm (sem privilegios de administrador)..."
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    if have curl; then
      curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash || return 1
    elif have wget; then
      wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash || return 1
    else
      echo "curl e wget nao encontrados."
      return 1
    fi
  fi

  . "$NVM_DIR/nvm.sh" || return 1
  nvm install --lts && nvm use --lts
}

install_macos() {
  if have brew; then
    echo "Instalando Node.js com Homebrew ($NODE_FORMULA)..."
    brew install "$NODE_FORMULA" && brew link --overwrite --force "$NODE_FORMULA" && return 0
    echo "Homebrew falhou, tentando nvm..."
  fi
  install_with_nvm
}

install_linux() {
  if have apt-get && have curl; then
    echo "Instalando Node.js LTS com apt (NodeSource)..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | as_root bash - \
      && as_root apt-get install -y nodejs && return 0
  elif have dnf && have curl; then
    echo "Instalando Node.js LTS com dnf (NodeSource)..."
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | as_root bash - \
      && as_root dnf install -y nodejs && return 0
  elif have yum && have curl; then
    echo "Instalando Node.js LTS com yum (NodeSource)..."
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | as_root bash - \
      && as_root yum install -y nodejs && return 0
  elif have pacman; then
    echo "Instalando Node.js com pacman..."
    as_root pacman -S --needed --noconfirm nodejs npm && return 0
  fi
  echo "Gerenciador de pacotes indisponivel ou falhou, tentando nvm..."
  install_with_nvm
}

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
  esac || {
    echo "Falha ao instalar o Node.js."
    pause_exit 1
  }

  hash -r
  if have brew; then
    brew_prefix="$(brew --prefix "$NODE_FORMULA" 2>/dev/null)"
    if [ -n "$brew_prefix" ] && [ -d "$brew_prefix/bin" ]; then
      export PATH="$brew_prefix/bin:$PATH"
    fi
  fi
fi

if ! have npm; then
  echo "npm nao encontrado. Feche o terminal e execute o script novamente."
  pause_exit 1
fi

if [ ! -f "src/package.json" ]; then
  echo "src/package.json nao encontrado em \"$(pwd)\"."
  pause_exit 1
fi

echo
echo "Instalando dependencias..."
if ! (cd src && npm install --omit=dev); then
  echo "Falha ao instalar as dependencias."
  pause_exit 1
fi

if [ ! -f "src/app.js" ]; then
  echo "src/app.js nao encontrado em \"$(pwd)\"."
  pause_exit 1
fi

echo
clear
echo "Node.js e as dependencias foram instaladas com sucesso."
echo "Iniciando: node src/app.js"
echo
node src/app.js &
sleep 1
firefox ./src/index.html &
pause_exit $?