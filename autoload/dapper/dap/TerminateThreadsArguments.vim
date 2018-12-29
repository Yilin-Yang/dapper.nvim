function! dapper#dap#TerminateThreadsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'TerminateThreadsArguments': 1},
    \ 'threadIds': [],
  \ }
  return l:new
endfunction

function! dapper#dap#TerminateThreadsArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'TerminateThreadsArguments')
  try
    let l:err = '(dapper#dap#TerminateThreadsArguments) Object is not of type TerminateThreadsArguments: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#TerminateThreadsArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
