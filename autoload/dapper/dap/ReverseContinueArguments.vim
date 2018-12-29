function! dapper#dap#ReverseContinueArguments#new() abort
  let l:new = {
    \ 'TYPE': {'ReverseContinueArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#ReverseContinueArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ReverseContinueArguments')
  try
    let l:err = '(dapper#dap#ReverseContinueArguments) Object is not of type ReverseContinueArguments: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#ReverseContinueArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
