#!/bin/bash

# EFFECTS:  Runs all test cases in this folder, using this directory's
#           localvimrc as well as neovim.
# DETAILS:  Taken, in part, from:
#               https://github.com/junegunn/vader.vim
#               https://github.com/neovim/neovim/issues/4842
# PARAM:    TEST_INTERNATIONAL  If set to '-i' or '--international', re-run
#                               tests in non-English locales.
BASE_CMD="nvim --headless -Nnu .test_vimrc -i NONE"
VADER_CMD="-c 'Vader!"
TEST_PAT=" test-*.vader'"
for ARG in "$@"; do
    case $ARG in
        '-i' | '--international')
            TEST_INTERNATIONAL=1
            ;;
        '-v' | '--visible')
            BASE_CMD="nvim -Nnu .test_vimrc -i NONE"
            VADER_CMD="-c 'Vader"
            ;;
        '--debug-logger')
            export DAPPER_TEST_DEBUG_LOGGING=1
            TEST_PAT=" log/test-*.vader'"
            ;;
        "--file="*)
            TEST_PAT="${ARG#*=}'"
            ;;
    esac
done
export IS_DAPPER_DEBUG=1

set -p
export VADER_OUTPUT_FILE=/dev/stderr
echo "${BASE_CMD} ${VADER_CMD} ${TEST_PAT}"
eval "${BASE_CMD} ${VADER_CMD} ${TEST_PAT}"

if [ $TEST_INTERNATIONAL ]; then
    # test non-English locale
    eval "${BASE_CMD} -c 'language de_DE.utf8' ${VADER_CMD} ${TEST_PAT}"
    eval "${BASE_CMD} -c 'language es_ES.utf8' ${VADER_CMD} ${TEST_PAT}"
fi
unset IS_DAPPER_DEBUG
export DAPPER_TEST_DEBUG_LOGGING=0
