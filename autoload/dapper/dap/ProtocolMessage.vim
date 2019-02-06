""
" @dict ProtocolMessage
" A basic Debug Adapter Protocol message, with dapper.nvim annotations.

let s:typename = 'ProtocolMessage'

""
" @public
" Returns a new ProtocolMessage object.
"
" [vim_id] is an ID corresponding to the VimL object associated with this message.
"
" [vim_msg_typename] is the 'full name' of this message type, e.g.
" `"ErrorResponse"`, `"LoadedSourceEvent"`, etc.
"
" @default [vim_msg_typename]="ProtocolMessage"
" @throws WrongType if [vim_id] is not a number of [vim_msg_typename] is not a string.
function! dapper#dap#ProtocolMessage#new(...)
  let l:vim_id = maktaba#ensure#IsNumber(get(a:000, 0, 0))
  let l:vim_msg_typename = maktaba#ensure#IsString(get(a:000, 1, s:typename))
  let l:new = {
    \ 'seq': 0,
    \ 'type': '',
    \ 'vim_id': l:vim_id,
    \ 'vim_msg_typename': l:vim_msg_typename,
  \ }
  return typevim#make#Class(s:typename, l:new)
endfunction
