#!/bin/sh
# error on both undefined variables and other errors
set -ue

vim_plug_path="${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim
NODE_BASE_URL="https://nodejs.org/dist/v16.15.0"
ARCH=$(uname -m)

if [ $ARCH == "x86_64" ]; then
    NODE_FILENAME="node-v16.15.0-linux-x64.tar.xz"
    NODE_URL="$NODE_BASE_URL/node-v16.15.0-linux-x64.tar.xz"
elif [ $ARCH == "armv7*" ]; then
    NODE_FILENAME="node-v16.15.0-linux-armv7l.tar.xz"
    NODE_URL="$NODE_BASE_URL/"
elif [ $ARCH == "armv8*" ]; then
    NODE_FILENAME="node-v16.15.0-linux-arm64.tar.xz"
    NODE_URL="$NODE_BASE_URL/$NODE_FILENAME"
else
    echo "unknown arch"
    exit 1
fi

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
    curl -S ${NODE_URL} \
        --output $HOME/bin/$NODE_FILENAME
    (
        cd ~/bin
        tar xvf "node-16.15.tar.xz"
        ln -sf "$NODE_PATH/bin/node" .
        ln -sf "$NODE_PATH/bin/npx" .
        ln -sf "$NODE_PATH/bin/npm" .
        rm "$HOME/bin/$NODE_FILENAME"
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

# gets all files except git and this file and gets the relative path
find "${search_path}" \( -path "${search_path}/.git" -prune -o \
    -type f \) -a \! \( -name 'link.sh' -o -name ".git*" \) -exec \
    ln -sf  "${current_path}/{}" "$HOME/{}" \; -print
