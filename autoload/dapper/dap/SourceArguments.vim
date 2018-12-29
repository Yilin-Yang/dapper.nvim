function! dapper#dap#SourceArguments#new() abort
  let l:new = {
    \ 'TYPE': {'SourceArguments': 1},
    \ 'source': {},
    \ 'sourceReference': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#SourceArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'SourceArguments')
    throw '(dapper#dap#SourceArguments) Object is not of type SourceArguments: ' . string(a:object)
  endif
endfunction
