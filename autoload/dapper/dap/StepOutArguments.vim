function! dapper#dap#StepOutArguments#new() abort
  let l:new = {
    \ 'TYPE': {'StepOutArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#StepOutArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StepOutArguments')
    throw '(dapper#dap#StepOutArguments) Object is not of type StepOutArguments: ' . string(a:object)
  endif
endfunction
