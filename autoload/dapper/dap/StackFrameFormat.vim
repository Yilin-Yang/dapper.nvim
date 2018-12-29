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
