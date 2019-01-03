function! dapper#dap#ContinueArguments#new() abort
  let l:new = {
    \ 'TYPE': {'ContinueArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#ContinueArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ContinueArguments')
  try
    let l:err = '(dapper#dap#ContinueArguments) Object is not of type ContinueArguments: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#ContinueArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
