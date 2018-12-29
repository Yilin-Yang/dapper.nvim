function! dapper#config#InitialBreakpoints#new(...) abort
  let a:bps = get(a:000, 0, {})
  let a:function_bps = get(a:000, 0, {})
  let a:exception_bps = get(a:000, 0, {})
  let l:new = {
    \ 'TYPE': {'InitialBreakpoints': 1},
    \ 'bps': a:bps,
    \ 'function_bps': a:function_bps,
    \ 'exception_bps': a:exception_bps,
  \ }
  return l:new
endfunction

function! dapper#config#InitialBreakpoints#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object['TYPE'], 'InitialBreakpoints')
    throw '(dapper#dap#InitialBreakpoints) Object is not of type InitialBreakpoints: ' . a:object
  endif
endfunction
