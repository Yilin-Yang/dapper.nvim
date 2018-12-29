function! dapper#dap#SetExpressionArguments#new() abort
  let l:new = {
    \ 'TYPE': {'SetExpressionArguments': 1},
    \ 'expression': '',
    \ 'value': '',
    \ 'frameId': 0,
    \ 'format': {},
  \ }
  return l:new
endfunction

function! dapper#dap#SetExpressionArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'SetExpressionArguments')
    throw '(dapper#dap#SetExpressionArguments) Object is not of type SetExpressionArguments: ' . string(a:object)
  endif
endfunction
