#!/bin/bash
# error on both undefined variables and other errors
set -ue

vim_plug_path="${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim

install_system_packages() {
    PACKAGES='curl libfuse2'
    if [ -z "$IZSH" ]; then
        PACKAGES="$PACKAGES zsh"
    fi

    if [ -f /usr/bin/apt ]; then
        PCKMGR=apt
        MGRFLAGS='install'
        REFRESH_PACKAGES='update'
        PACKAGES="${PACKAGES} texlive latexmk"
    elif [ -f /usr/bin/pacman ]; then
        PCKMGR=pacman
        MGRFLAGS='-S'
        REFRESH_PACKAGES='-Syy'
        PACKAGES="${PACKAGES} texlive-most"
    fi

    sudo $PCKMGR $REFRESH_PACKAGES
    sudo $PCKMGR $MGRFLAGS $PACKAGES
}

IZSH=
NOSUDO=
while getopts 'zn' opt
do
    case "$opt" in
        z)
            IZSH=1
            ;;
        n)
            NOSUDO=1
            ;;
        ?)
            echo -e "usage: ./link.sh [-n] [-z]\n\t-z Do not install zsh\n\t-n No sudo use"
            exit 1
            ;;
    esac
done

if [ "${NOSUDO}" ]; then
    install_system_packages
fi

NODE_BASE_URL="https://nodejs.org/dist/v16.15.0"
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    NODE_FILENAME="node-v16.15.0-linux-x64"
elif [ "$ARCH" = "armv7*" ]; then
    NODE_FILENAME="node-v16.15.0-linux-armv7l"
elif [ "$ARCH" = "armv8*" ]; then
    NODE_FILENAME="node-v16.15.0-linux-arm64"
else
    echo "unknown arch"
    exit 1
fi

NODE_TAR_NAME="$NODE_FILENAME.tar.xz"
NODE_URL="$NODE_BASE_URL/$NODE_TAR_NAME"
NODE_PATH="$HOME/bin/$NODE_FILENAME"

mkdir -p ~/.config/nvim
mkdir -p $HOME/bin

check_exists() {
    if [ -z "$1" ]; then
        echo "No argument given to check_exists"
    fi
    if [ -z $(type -P "$1") ]; then
        echo "$1 does not exist"
		exit 1
    fi
}

check_exists "curl"

wget --quiet https://github.com/neovim/neovim/releases/download/stable/nvim.appimage --output-document "$HOME/bin/vim" && chmod +x "$HOME/bin/vim"|| echo "failed to install nvim"

if [[ -n "$IZSH" && $(check_exists "zsh") ]]; then
	echo "Installing oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
	echo "Will not install oh-my-zsh"
fi

if [ ! -d "$NODE_PATH" ]
then
    echo "Installing node"
    curl -S ${NODE_URL} \
        --output $HOME/bin/$NODE_TAR_NAME
    (
        cd ~/bin
        tar xf "$NODE_TAR_NAME"
        ln -sf "$NODE_PATH/bin/node" .
        ln -sf "$NODE_PATH/bin/npx" .
        ln -sf "$NODE_PATH/bin/npm" .
        rm "$HOME/bin/$NODE_TAR_NAME"
        echo "installing yarn for markdown-preview"
        ./npm install --global yarn tree-sitter-cli
        echo "export PATH=\"$(npm bin -g):\$PATH\"" >> "$HOME/.bashrc"
    )
fi

if [ ! -f "${vim_plug_path}" ]
then
    echo "Installing vim-plug"
    sh -c "curl -sfLo ${vim_plug_path} --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
fi

search_path=.
current_path=$(pwd)

echo "Linking dotfiles"
ignored_files=('install.sh' 'link.sh' '.gitignore' '.git' '*.swp')
ignore_flags=$(printf -- '-name %s -o ' ${ignored_files[@]} | sed 's/\-o $//')

# gets all files except git and this file and gets the relative path
find "${search_path}" \( -path "${search_path}/.git" -prune -o \
    -type f \) -a \! \( ${ignore_flags} \) \
    -exec ln -sf  "${current_path}/{}" "$HOME/{}" \; -print
