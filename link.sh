#!/bin/sh
set -u
vim_plug_path="${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim
NODE_PATH="$HOME/bin/node-v16.15.0-linux-x64"

mkdir -p ~/.config/nvim
mkdir -p $HOME/bin

if ! curl -V > /dev/null
then
    echo "curl not installed"
    exit 1
fi

if [ ! -d "$NODE_PATH" ]
then
    curl -S "https://nodejs.org/dist/v16.15.0/node-v16.15.0-linux-x64.tar.xz" \
        --output $HOME/bin/node-16.15.tar.xz
    (
        cd ~/bin
        tar xvf "node-16.15.tar.xz"
        ln -sf "$NODE_PATH/bin/node" .
        ln -sf "$NODE_PATH/bin/npx" .
        ln -sf "$NODE_PATH/bin/npm" .
        rm "$HOME/bin/node-16.15.tar.xz"
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
