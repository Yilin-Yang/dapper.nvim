function! dapper#dap#StepInTargetsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'StepInTargetsArguments': 1},
    \ 'frameId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#StepInTargetsArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StepInTargetsArguments')
  try
    let l:err = '(dapper#dap#StepInTargetsArguments) Object is not of type StepInTargetsArguments: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#StepInTargetsArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
