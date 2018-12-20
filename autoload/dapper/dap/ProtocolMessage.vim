" RETURNS:  A new ProtocolMessage object.
" PARAM:  vim_id  (v:t_number?)   An ID corresponding to the VimL object
"                                 associated with this message.
function! dapper#dap#ProtocolMessage#new(...)
  let l:vim_id = get(a:000, 0, 0)
  return {
    \ 'seq': 0,
    \ 'type': '',
    \ 'vim_id': l:vim_id,
    \ 'vim_msg_typename': ''
  \ }
endfunction
