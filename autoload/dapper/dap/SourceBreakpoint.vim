function! dapper#dap#SourceBreakpoint#new() abort
  let l:new = {
    \ 'TYPE': {'SourceBreakpoint': 1},
    \ 'line': 0,
    \ 'column': 0,
    \ 'condition': '',
    \ 'hitCondition': '',
    \ 'logMessage': '',
  \ }
  return l:new
endfunction

function! dapper#dap#SourceBreakpoint#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'SourceBreakpoint')
  try
    let l:err = '(dapper#dap#SourceBreakpoint) Object is not of type SourceBreakpoint: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#SourceBreakpoint) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
