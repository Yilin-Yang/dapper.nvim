#!/bin/bash

# EFFECTS:  - Manually "installs" vscode-mock-debug and vscode-node-debug2 into
#           `node_modules`.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p "$DIR/node_modules"

DEPS="
    Microsoft/vscode-mock-debug
    Microsoft/vscode-node-debug2
"
for PACKAGE in $DEPS; do
    REPO="`echo $PACKAGE | cut -d'/' -f2`"
    cd "$DIR/node_modules"
    rm -rf "$REPO"
    git clone "https://github.com/$PACKAGE"
    cd "$REPO"
    yarn install
done
