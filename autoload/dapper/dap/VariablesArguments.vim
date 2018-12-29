function! dapper#dap#VariablesArguments#new() abort
  let l:new = {
    \ 'TYPE': {'VariablesArguments': 1},
    \ 'variablesReference': 0,
    \ 'filter': '',
    \ 'start': 0,
    \ 'count': 0,
    \ 'format': {},
  \ }
  return l:new
endfunction

function! dapper#dap#VariablesArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'VariablesArguments')
    throw '(dapper#dap#VariablesArguments) Object is not of type VariablesArguments: ' . string(a:object)
  endif
endfunction
