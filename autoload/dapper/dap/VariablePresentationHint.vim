function! dapper#dap#VariablePresentationHint#new() abort
  let l:new = {
    \ 'TYPE': {'VariablePresentationHint': 1},
    \ 'kind': '',
    \ 'attributes': '',
    \ 'visibility': '',
  \ }
  return l:new
endfunction

function! dapper#dap#VariablePresentationHint#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'VariablePresentationHint')
  try
    let l:err = '(dapper#dap#VariablePresentationHint) Object is not of type VariablePresentationHint: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#VariablePresentationHint) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
