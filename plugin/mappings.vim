""
" @section Mappings mappings
" dapper.nvim provides default mappings that only activate in: (1)
" dapper-created windows and buffers, and (2) source buffers that are
" controlled by dapper.nvim
"
" These mappings are meant to loosely replicate the keymappings that would be
" used in a common graphical debugger, namely Visual Studio Code. In general,
" they lack a prefix.
let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif


