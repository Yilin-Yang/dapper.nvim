function! dapper#dap#StepInArguments#new() abort
  let l:new = {
    \ 'TYPE': {'StepInArguments': 1},
    \ 'threadId': 0,
    \ 'targetId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#StepInArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StepInArguments')
    throw '(dapper#dap#StepInArguments) Object is not of type StepInArguments: ' . string(a:object)
  endif
endfunction
