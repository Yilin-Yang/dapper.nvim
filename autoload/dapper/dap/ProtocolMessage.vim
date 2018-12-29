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

function! dapper#dap#ProtocolMessage#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ProtocolMessage')
  try
    let l:err = '(dapper#dap#ProtocolMessage) Object is not of type ProtocolMessage: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#ProtocolMessage) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
