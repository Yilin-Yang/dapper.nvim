function! dapper#dap#GotoArguments#new() abort
  let l:new = {
    \ 'TYPE': {'GotoArguments': 1},
    \ 'threadId': 0,
    \ 'targetId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#GotoArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'GotoArguments')
  try
    let l:err = '(dapper#dap#GotoArguments) Object is not of type GotoArguments: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#GotoArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
