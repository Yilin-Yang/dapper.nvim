#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# cd into this directory
cd "$DIR"

# terminate on first command failure
set -e

##
# Generic algorithm for cloning and installing a debug adapter protocol
# extension into this folder.
#
# @param GIT_URL  git URL from which to clone the extension.
function install_extension() {
  local GIT_URL=$1
  local REPONAME
  REPONAME="$(echo "$GIT_URL" | rev | cut -d'/' -f1 | rev)"

  git clone "$GIT_URL" "$DIR/$REPONAME"
  cd "$DIR/$REPONAME"
  yarn install
  cd "$DIR"
}
