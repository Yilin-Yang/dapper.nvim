function! dapper#dap#RestartFrameArguments#new() abort
  let l:new = {
    \ 'TYPE': {'RestartFrameArguments': 1},
    \ 'frameId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#RestartFrameArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'RestartFrameArguments')
  try
    let l:err = '(dapper#dap#RestartFrameArguments) Object is not of type RestartFrameArguments: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#RestartFrameArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
