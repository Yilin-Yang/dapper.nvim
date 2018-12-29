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
  try
    let l:err = '(dapper#dap#Variable) Object is not of type Variable: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#Variable) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
