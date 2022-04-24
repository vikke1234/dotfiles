#!/bin/sh
set -u

search_path=.
current_path=$(pwd)

# gets all files except git and this file and gets the relative path
find "${search_path}" \( -path "${search_path}/.git" -prune -o \
    -type f \) -a \! \( -name 'link.sh' -o -name ".git*" \) -exec \
    ln -sf  "${current_path}/{}" "$HOME/{}" \; -print
