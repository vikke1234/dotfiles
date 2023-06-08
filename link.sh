#!/bin/bash
# error on both undefined variables and other errors
set -ue

install_system_packages() {
    PACKAGES='curl'
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

if [ ! -z "${NOSUDO}" ]; then
    install_system_packages
fi

if [ ! -d "$HOME/.oh-my-zsh" ] && [ ! -z "${IZSH}" ]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if [ -f /usr/bin/nvim ]; then
    vim_plug_path="${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim
else
    vim_plug_path="~/.vim/autoload/plug.vim"
    ln -s $HOME/.config/nvim/init.vim $HOME/.vimrc || true
fi


NODE_BASE_URL="https://nodejs.org/dist/v16.15.0"
ARCH=$(uname -m)

if [ $ARCH = "x86_64" ]; then
    NODE_FILENAME="node-v16.15.0-linux-x64"
elif [ $ARCH = "armv7*" ]; then
    NODE_FILENAME="node-v16.15.0-linux-armv7l"
elif [ $ARCH = "armv8*" ]; then
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
    $1 > /dev/null
    if [ $? != 0 ]; then
        echo "$1 does not exist"
    fi
}

check_exists "curl -V"
check_exists "zsh --version"

wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage --output-document "$HOME/bin/vim" || echo "failed to install nvim"

if [ -z "$IZSH" ]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
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
    )
fi

if [ ! -f "${vim_plug_path}" ]
then
    echo "installing vim-plug"
    sh -c "curl -fLo ${vim_plug_path} --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
fi

search_path=.
current_path=$(pwd)

echo "Linking dotfiles"
ignored_files=('install.sh' 'link.sh' '.git*')
ignore_flags=$(printf -- '-name %s -o ' ${ignored_files[@]} | sed 's/\-o $//')

# gets all files except git and this file and gets the relative path
find "${search_path}" \( -path "${search_path}/.git" -prune -o \
    -type f \) -a \! \( ${ignore_flags} \) \
    -exec ln -sf  "${current_path}/{}" "$HOME/{}" \; -print
