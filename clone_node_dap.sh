#!/bin/bash

# EFFECTS:  Clones and `npm install`s vscode-node-debug2 into the build folder,
#           at a location hardcoded into the repo's current TypeScript source.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p build
git clone https://github.com/Microsoft/vscode-node-debug2.git "$DIR/build"

cd build/vscode-node-debug2
npm install
