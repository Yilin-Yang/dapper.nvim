function! dapper#dap#ReverseContinueArguments#new() abort
  let l:new = {
    \ 'TYPE': {'ReverseContinueArguments': 1},
    \ 'threadId': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#ReverseContinueArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ReverseContinueArguments')
    throw '(dapper#dap#ReverseContinueArguments) Object is not of type ReverseContinueArguments: ' . string(a:object)
  endif
endfunction
