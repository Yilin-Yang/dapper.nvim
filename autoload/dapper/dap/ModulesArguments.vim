function! dapper#dap#ModulesArguments#new() abort
  let l:new = {
    \ 'TYPE': {'ModulesArguments': 1},
    \ 'startModule': 0,
    \ 'moduleCount': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#ModulesArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ModulesArguments')
    throw '(dapper#dap#ModulesArguments) Object is not of type ModulesArguments: ' . string(a:object)
  endif
endfunction
