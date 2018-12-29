function! dapper#dap#GotoTarget#new() abort
  let l:new = {
    \ 'TYPE': {'GotoTarget': 1},
    \ 'id': 0,
    \ 'label': '',
    \ 'line': 0,
    \ 'column': 0,
    \ 'endLine': 0,
    \ 'endColumn': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#GotoTarget#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'GotoTarget')
    throw '(dapper#dap#GotoTarget) Object is not of type GotoTarget: ' . string(a:object)
  endif
endfunction
