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
    throw '(dapper#dap#SetBreakpointsArguments) Object is not of type SetBreakpointsArguments: ' . string(a:object)
  endif
endfunction
