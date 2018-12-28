function! dapper#dap#EvaluateArguments() abort
  let l:new = {
    \ 'TYPE': {'EvaluateArguments': 1},
    \ 'expression': '',
    \ 'frameId': 0,
    \ 'context': '',
    \ 'format': {},
  \ }
  return l:new
endfunction
