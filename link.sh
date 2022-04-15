#!/bin/sh
set -u
set -e

# would prefer if I found a way to get relative paths for linking but it
# doesn't matter I suppose
find . \( -path ./.git -prune -o -type f \) -a \
    \! \( -name 'link.sh' -o -name ".git*" \) \
    -exec /bin/ln -s $HOME/{} {} \;
