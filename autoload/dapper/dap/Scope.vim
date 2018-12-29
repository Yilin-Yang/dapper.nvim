function! dapper#dap#Scope#new() abort
  let l:new = {
    \ 'TYPE': {'Scope': 1},
    \ 'name': '',
    \ 'variablesReference': 0,
    \ 'namedVariables': 0,
    \ 'indexedVariables': 0,
    \ 'expensive': v:false,
    \ 'source': {},
    \ 'line': 0,
    \ 'column': 0,
    \ 'endLine': 0,
    \ 'endColumn': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#Scope#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Scope')
    throw '(dapper#dap#Scope) Object is not of type Scope: ' . string(a:object)
  endif
endfunction
