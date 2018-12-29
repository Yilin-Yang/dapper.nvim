function! dapper#dap#SetVariableArguments#new() abort
  let l:new = {
    \ 'TYPE': {'SetVariableArguments': 1},
    \ 'variablesReference': 0,
    \ 'name': '',
    \ 'value': '',
    \ 'format': {},
  \ }
  return l:new
endfunction

function! dapper#dap#SetVariableArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'SetVariableArguments')
    throw '(dapper#dap#SetVariableArguments) Object is not of type SetVariableArguments: ' . string(a:object)
  endif
endfunction
