function! dapper#dap#SetExpressionArguments#new() abort
  let l:new = {
    \ 'TYPE': {'SetExpressionArguments': 1},
    \ 'expression': '',
    \ 'value': '',
    \ 'frameId': 0,
    \ 'format': {},
  \ }
  return l:new
endfunction
