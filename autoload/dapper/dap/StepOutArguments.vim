function! dapper#dap#StepOutArguments#new() abort
  let l:new = {
    \ 'TYPE': {'StepOutArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#StepOutArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StepOutArguments')
  try
    let l:err = '(dapper#dap#StepOutArguments) Object is not of type StepOutArguments: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#StepOutArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
