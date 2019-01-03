function! dapper#dap#StackFrameFormat#new() abort
  let l:new = {
    \ 'TYPE': {'StackFrameFormat': 1},
    \ 'parameters': v:false,
    \ 'parameterTypes': v:false,
    \ 'parameterNames': v:false,
    \ 'parameterValues': v:false,
    \ 'line': v:false,
    \ 'module': v:false,
    \ 'includeAll': v:false,
  \ }
  return l:new
endfunction

function! dapper#dap#StackFrameFormat#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StackFrameFormat')
  try
    let l:err = '(dapper#dap#StackFrameFormat) Object is not of type StackFrameFormat: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#StackFrameFormat) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
