""
" @dict SourceBuffer
" Shows debuggee source code, and the current execution context. Can set
" breakpoints, or step line-by-line.

let s:plugin = maktaba#plugin#Get('dapper.nvim')

let s:typename = 'SourceBuffer'
let s:counter = 0

function! dapper#view#SourceBuffer#New(message_passer) abort
endfunction
