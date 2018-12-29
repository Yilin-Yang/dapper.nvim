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
  try
    let l:err = '(dapper#dap#GotoTarget) Object is not of type GotoTarget: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#GotoTarget) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
