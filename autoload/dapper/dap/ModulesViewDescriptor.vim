function! dapper#dap#ModulesViewDescriptor#new() abort
  let l:new = {
    \ 'TYPE': {'ModulesViewDescriptor': 1},
    \ 'columns': [],
  \ }
  return l:new
endfunction

function! dapper#dap#ModulesViewDescriptor#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ModulesViewDescriptor')
    throw '(dapper#dap#ModulesViewDescriptor) Object is not of type ModulesViewDescriptor: ' . string(a:object)
  endif
endfunction
