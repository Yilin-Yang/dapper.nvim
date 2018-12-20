" RETURNS:  A new ProtocolMessage object.
" PARAM:  vim_id  (v:t_number?)   An ID corresponding to the VimL object
"                                 associated with this message.
" PARAM:  vim_msg_typename  (v:t_string)  The 'full name' of this message
"                                         type, e.g. 'ErrorResponse',
"                                         'LoadedSourceEvent', etc.
function! dapper#dap#ProtocolMessage#new(...)
  let l:vim_id = get(a:000, 0, 0)
  let l:vim_msg_typename = get(a:000, 1, 'ProtocolMessage')
  return {
    \ 'seq': 0,
    \ 'type': '',
    \ 'vim_id': l:vim_id,
    \ 'vim_msg_typename': l:vim_msg_typename,
  \ }
endfunction
