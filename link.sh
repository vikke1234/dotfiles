#!/bin/sh
set -u

search_path=.

# gets all files except git and this file and gets the relative path
files=$(find "${search_path}" \( -path "${search_path}/.git" -prune -o \
    -type f \) -a \! \( -name 'link.sh' -o -name ".git*" \) -print0 | \
    xargs -0 realpath --relative-to=${search_path})

for file in $files
do
    ln -sf "$(pwd)/$file" "$HOME/$file"
done
