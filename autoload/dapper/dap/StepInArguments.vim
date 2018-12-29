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
  try
    let l:err = '(dapper#dap#StepInArguments) Object is not of type StepInArguments: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#StepInArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
