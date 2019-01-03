function! dapper#dap#FunctionBreakpoint#new() abort
  let l:new = {
    \ 'TYPE': {'FunctionBreakpoint': 1},
    \ 'name': '',
    \ 'condition': '',
    \ 'hitCondition': '',
  \ }
  return l:new
endfunction

function! dapper#dap#FunctionBreakpoint#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'FunctionBreakpoint')
  try
    let l:err = '(dapper#dap#FunctionBreakpoint) Object is not of type FunctionBreakpoint: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#FunctionBreakpoint) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
