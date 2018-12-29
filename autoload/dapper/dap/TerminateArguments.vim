function! dapper#dap#Terminaterguments#new() abort
  let l:new = {
    \ 'TYPE': {'TerminateArguments': 1},
    \ 'restart': v:false,
  \ }
  return l:new
endfunction

function! dapper#dap#TerminateArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'TerminateArguments')
    throw '(dapper#dap#TerminateArguments) Object is not of type TerminateArguments: ' . string(a:object)
  endif
endfunction
