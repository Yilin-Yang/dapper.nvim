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
    throw '(dapper#dap#VariablePresentationHint) Object is not of type VariablePresentationHint: ' . string(a:object)
  endif
endfunction
