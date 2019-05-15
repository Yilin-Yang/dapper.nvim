#!/bin/bash
source "$(dirname "$0")/global_constants.sh"

clone_extension https://github.com/Yilin-Yang/vscode-mock-debug
yarn install  # TODO use --ignore-engines + switch to upstream Microsoft repo?
yarn compile
