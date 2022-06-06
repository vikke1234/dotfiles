#!/bin/sh
# error on both undefined variables and other errors
set -ue

if [ -f /usr/bin/nvim ]; then
    vim_plug_path="${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim
else
    vim_plug_path="~/.vim/autoload/plug.vim"
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

if ! curl -V > /dev/null
then
    echo "curl not installed"
    exit 1
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
# gets all files except git and this file and gets the relative path
find "${search_path}" \( -path "${search_path}/.git" -prune -o \
    -type f \) -a \! \( -name 'link.sh' -o -name ".git" -o -name ".gitignore" \) -exec \
    ln -sf  "${current_path}/{}" "$HOME/{}" \; -print
