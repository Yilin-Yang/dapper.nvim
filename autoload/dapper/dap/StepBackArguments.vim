function! dapper#dap#StepBackArguments#new() abort
  let l:new = {
    \ 'TYPE': {'StepBackArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#StepBackArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StepBackArguments')
  try
    let l:err = '(dapper#dap#StepBackArguments) Object is not of type StepBackArguments: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#StepBackArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
