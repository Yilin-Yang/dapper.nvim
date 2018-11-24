#!/bin/bash

# EFFECTS:  Clones and `npm install`s vscode-mock-debug into the build folder,
#           at a location hardcoded into the repo's current TypeScript source.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p build
git clone https://github.com/Microsoft/vscode-mock-debug.git "$DIR/build/vscode-mock-debug"
cd build/vscode-mock-debug
npm install
