function! dapper#dap#ExceptionBreakpointsFilter#new() abort
  let l:new = {
    \ 'TYPE': {'ExceptionBreakpointsFilter': 1},
    \ 'filter': '',
    \ 'label': '',
    \ 'default': v:false,
  \ }
  return l:new
endfunction

function! dapper#dap#ExceptionBreakpointsFilter#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ExceptionBreakpointsFilter')
  try
    let l:err = '(dapper#dap#ExceptionBreakpointsFilter) Object is not of type ExceptionBreakpointsFilter: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#ExceptionBreakpointsFilter) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
