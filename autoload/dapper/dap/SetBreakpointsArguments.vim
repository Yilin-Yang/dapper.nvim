function! dapper#dap#SetBreakpointsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'SetBreakpointsArguments': 1},
    \ 'source': {},
    \ 'breakpoints': [],
    \ 'lines': [],
    \ 'sourceModified': v:false,
  \ }
  return l:new
endfunction

function! dapper#dap#SetBreakpointsArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'SetBreakpointsArguments')
  try
    let l:err = '(dapper#dap#SetBreakpointsArguments) Object is not of type SetBreakpointsArguments: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#SetBreakpointsArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
