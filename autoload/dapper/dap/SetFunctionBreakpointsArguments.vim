function! dapper#dap#SetFunctionBreakpointsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'SetFunctionBreakpointsArguments': 1},
    \ 'breakpoints': [],
  \ }
  return l:new
endfunction

function! dapper#dap#SetFunctionBreakpointsArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'SetFunctionBreakpointsArguments')
    throw '(dapper#dap#SetFunctionBreakpointsArguments) Object is not of type SetFunctionBreakpointsArguments: ' . string(a:object)
  endif
endfunction
