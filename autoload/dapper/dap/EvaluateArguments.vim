function! dapper#dap#EvaluateArguments#new() abort
  let l:new = {
    \ 'TYPE': {'EvaluateArguments': 1},
    \ 'expression': '',
    \ 'frameId': 0,
    \ 'context': '',
    \ 'format': {},
  \ }
  return l:new
endfunction

function! dapper#dap#EvaluateArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'EvaluateArguments')
    throw '(dapper#dap#EvaluateArguments) Object is not of type EvaluateArguments: ' . string(a:object)
  endif
endfunction
