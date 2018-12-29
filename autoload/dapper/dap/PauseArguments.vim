function! dapper#dap#PauseArguments#new() abort
  let l:new = {
    \ 'TYPE': {'PauseArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#PauseArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'PauseArguments')
    throw '(dapper#dap#PauseArguments) Object is not of type PauseArguments: ' . string(a:object)
  endif
endfunction
