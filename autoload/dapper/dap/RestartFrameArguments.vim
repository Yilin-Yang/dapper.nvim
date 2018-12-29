function! dapper#dap#RestartFrameArguments#new() abort
  let l:new = {
    \ 'TYPE': {'RestartFrameArguments': 1},
    \ 'frameId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#RestartFrameArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'RestartFrameArguments')
    throw '(dapper#dap#RestartFrameArguments) Object is not of type RestartFrameArguments: ' . string(a:object)
  endif
endfunction
