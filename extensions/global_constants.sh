#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# cd into this directory
cd "$DIR"

# terminate on first command failure
set -e

##
# Generic algorithm for cloning a debug adapter protocol extension into this
# folder. DELETES any preexisting extension, if one is found. On return from
# this function, the cloned repo folder will be the CWD.
#
# The caller should perform any actual setup/installation steps.
#
# @param GIT_URL  git URL from which to clone the extension.
function clone_extension() {
  local GIT_URL=$1
  local REPONAME
  REPONAME="$(echo "$GIT_URL" | rev | cut -d'/' -f1 | rev)"

  if [ -a "$DIR/$REPONAME" ]; then
    echo "Detected existing \"$REPONAME\", removing."
    rm -rfv "${DIR:?}/$REPONAME"
  fi

  git clone "$GIT_URL" "$DIR/$REPONAME"
  cd "$DIR/$REPONAME"
}
