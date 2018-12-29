function! dapper#dap#Variable#new() abort
  let l:new = {
    \ 'TYPE': {'Variable': 1},
    \ 'name': '',
    \ 'value': '',
    \ 'type': '',
    \ 'presentationHint': {},
    \ 'evaluateName': '',
    \ 'variablesReference': 0,
    \ 'namedVariables': 0,
    \ 'indexedVariables': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#Variable#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Variable')
    throw '(dapper#dap#Variable) Object is not of type Variable: ' . string(a:object)
  endif
endfunction
