function! dapper#dap#AttachRequestArguments#new() abort
  let l:new = {
    \ 'TYPE': {'AttachRequestArguments': 1},
    \ '__restart': {},
  \ }
  return l:new
endfunction

function! dapper#dap#AttachRequestArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'AttachRequestArguments')
    throw '(dapper#dap#AttachRequestArguments) Object is not of type AttachRequestArguments: ' . string(a:object)
  endif
endfunction
