function! dapper#dap#GotoTargetsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'GotoTargetsArguments': 1},
    \ 'source': {},
    \ 'line': 0,
    \ 'column': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#GotoTargetsArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'GotoTargetsArguments')
  try
    let l:err = '(dapper#dap#GotoTargetsArguments) Object is not of type GotoTargetsArguments: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#GotoTargetsArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
