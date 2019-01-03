function! dapper#dap#SetFunctionBreakpointsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'SetFunctionBreakpointsArguments': 1},
    \ 'breakpoints': [],
  \ }
  return l:new
endfunction

function! dapper#dap#SetFunctionBreakpointsArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'SetFunctionBreakpointsArguments')
  try
    let l:err = '(dapper#dap#SetFunctionBreakpointsArguments) Object is not of type SetFunctionBreakpointsArguments: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#SetFunctionBreakpointsArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
