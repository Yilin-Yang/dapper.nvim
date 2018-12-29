function! dapper#dap#Thread#new() abort
  let l:new = {
    \ 'TYPE': {'Thread': 1},
    \ 'id': 0,
    \ 'name': '',
  \ }
  return l:new
endfunction

function! dapper#dap#Thread#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Thread')
    throw '(dapper#dap#Thread) Object is not of type Thread: ' . string(a:object)
  endif
endfunction
