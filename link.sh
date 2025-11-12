#!/bin/bash
# Strict bash mode for predictable errors
set -euo pipefail

#--- CONFIGURATION ---
VIM_PLUG_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
NODE_VERSION="v16.15.0"
NODE_BASE_URL="https://nodejs.org/dist/${NODE_VERSION}"

#--- ARGUMENT PARSING ---
INSTALL_ZSH=1
USE_SUDO=1

usage() {
    echo "usage: $0 [-n] [-z]"
    echo "  -z  Do not install Zsh"
    echo "  -n  No sudo use"
    exit 1
}

while getopts 'zn' opt
do
    case "$opt" in
        z) INSTALL_ZSH=0 ;;
        n) USE_SUDO=0 ;;
        *) usage ;;
    esac
done

#--- UTILITIES ---
check_exists() {
    local cmd="$1"
    if ! command -v "$cmd" > /dev/null 2>&1; then
        echo "$cmd is required but not installed."
        exit 1
    fi
}

run_sudo() {
    if [ "$USE_SUDO" -eq 1 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

#--- DETECT PACKAGE MANAGER ---
detect_pkgmgr() {
    if command -v apt > /dev/null 2>&1; then
        echo "apt"
    elif command -v pacman > /dev/null 2>&1; then
        echo "pacman"
    elif command -v dnf > /dev/null 2>&1; then
        echo "dnf"
    else
        echo "unknown"
    fi
}

install_system_packages() {
    local pkgs=("curl" "libfuse2")
    [ "$INSTALL_ZSH" -eq 1 ] && pkgs+=("zsh")
    local pkgmgr
    pkgmgr=$(detect_pkgmgr)

    case "$pkgmgr" in
        apt)
            pkgs+=("texlive" "latexmk")
            run_sudo apt update
            run_sudo apt install -y "${pkgs[@]}"
            ;;
        pacman)
            pkgs+=("texlive-most")
            run_sudo pacman -Syy
            run_sudo pacman -S --noconfirm "${pkgs[@]}"
            ;;
        dnf)
            pkgs+=("texlive")
            run_sudo dnf install -y "${pkgs[@]}"
            ;;
        *)
            echo "No supported package manager found."
            exit 1
            ;;
    esac
}

#--- NODE ARCH DETECTION ---
detect_node_filename() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) echo "node-${NODE_VERSION}-linux-x64" ;;
        armv7l) echo "node-${NODE_VERSION}-linux-armv7l" ;;
        aarch64) echo "node-${NODE_VERSION}-linux-arm64" ;;
        *) echo "unknown"; return 1 ;;
    esac
}

#--- SETUP DIRECTORIES ---
mkdir -p "$HOME/bin" "$HOME/.config/nvim"

#--- INSTALL PACKAGES ---
install_system_packages

#--- NEOVIM BINARY ---
check_exists "curl"
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage" ;;
    aarch64) NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.appimage" ;;
    *) echo "Unsupported architecture for Neovim AppImage"; exit 1 ;;
esac

curl -fsSL "$NVIM_URL" -o "$HOME/bin/nvim" && chmod +x "$HOME/bin/nvim" || { echo "Failed to install Neovim"; exit 1; }


#--- ZSH + OH-MY-ZSH ---
if [ "$INSTALL_ZSH" -eq 1 ]; then
    check_exists "zsh"
    echo "Installing oh-my-zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "Oh-my-zsh already installed at $HOME/.oh-my-zsh, skipping."
    else
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
else
    echo "Skipping oh-my-zsh install."
fi

#--- NODE AND YARN ---
echo "Installing node"
NODE_FILENAME=$(detect_node_filename)
if [ "$NODE_FILENAME" = "unknown" ]; then
    echo "Unknown architecture for Node.js install."
    exit 1
fi
NODE_TAR_NAME="${NODE_FILENAME}.tar.xz"
NODE_URL="${NODE_BASE_URL}/${NODE_TAR_NAME}"
NODE_PATH="$HOME/bin/${NODE_FILENAME}"

if [ ! -d "$NODE_PATH" ]; then
    echo "Installing Node.js..."
    curl -fsS "$NODE_URL" -o "$HOME/bin/$NODE_TAR_NAME"
    ( 
        cd "$HOME/bin"
        tar xf "$NODE_TAR_NAME"
        ln -sf "$NODE_PATH/bin/node" .
        ln -sf "$NODE_PATH/bin/npx" .
        ln -sf "$NODE_PATH/bin/npm" .
        rm "$NODE_TAR_NAME"
        ./npm install --global yarn tree-sitter-cli
        echo 'export PATH="$(npm bin -g):$PATH"' >> "$HOME/.bashrc"
    )
fi

#--- LINK DOTFILES ---
echo "Linking dotfiles..."
IGNORED_FILES=('install.sh' 'link.sh' '.gitignore' '.git' '*.swp')
SEARCH_PATH=.
CURRENT_PATH=$(pwd)
IGNORE_FLAGS=$(printf -- '-name %s -o ' "${IGNORED_FILES[@]}" | sed 's/ -o $//')

find "$SEARCH_PATH" \( -path "$SEARCH_PATH/.git" -prune -o -type f \) -a \
    \! \( $IGNORE_FLAGS \) \
    -exec ln -sf "$CURRENT_PATH/{}" "$HOME/{}" \; -print

echo "Setup completed successfully."
