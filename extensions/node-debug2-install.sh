#!/bin/bash
source "$(dirname "$0")/global_constants.sh"

clone_extension https://github.com/Microsoft/vscode-node-debug2
# the repo expects npm instead of yarn, but use yarn anyway because
# npm often fails for no reason
yarn install
yarn build
