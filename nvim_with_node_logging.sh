#!/bin/bash

# EFFECTS:  - Run neovim, with Node.js debug logging enabled to `LOGFILE`.
#           - Wipes the current contents of LOGFILE.

LOGFILE="LOGFILE"
export NVIM_NODE_LOG_FILE=$LOGFILE

printf '' > "$LOGFILE"
nvim
cat "$LOGFILE"

export NVIM_NODE_LOG_FILE=
