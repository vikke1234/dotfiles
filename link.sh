#!/bin/sh
set -u
vim_plug_path="${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim

curl -V

if [ $? != 0 ]
then
    echo "curl not installed"
    exit 1
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
