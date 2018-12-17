#!/bin/bash

# EFFECTS:  "Register" plugin commands in the remote plugin manifest.
# DETAILS:  Workaround for broken Node.js remote plugin registration.

MANIFEST="$HOME/.local/share/nvim/rplugin.vim"

# strip empty remote plugin registration, if present
nvim -n -u NONE -i NONE --headless "$MANIFEST" -c "%s/\n^.\{-}dapper.nvim'\_.\{-}).\{-}//e" -cwq

cat << EOF >> "$MANIFEST"
call remote#host#RegisterPlugin('node', '/home/yiliny/plugin/dapper.nvim/rplugin/node/dapper.nvim', [
      \ {'sync': v:false, 'name': 'DapperStart', 'type': 'command', 'opts': {'nargs': '+'}},
      \ {'sync': v:false, 'name': 'DapperRequest', 'type': 'function', 'opts': {}},
     \ ])
EOF
