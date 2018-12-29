function! dapper#dap#PauseArguments#new() abort
  let l:new = {
    \ 'TYPE': {'PauseArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#PauseArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'PauseArguments')
  try
    let l:err = '(dapper#dap#PauseArguments) Object is not of type PauseArguments: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#PauseArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
