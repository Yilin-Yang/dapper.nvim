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
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'InitialBreakpoints')
  try
    let l:err = '(dapper#dap#InitialBreakpoints) Object is not of type InitialBreakpoints: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#InitialBreakpoints) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
