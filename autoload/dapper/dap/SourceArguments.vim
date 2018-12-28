function! dapper#dap#SourceArguments() abort
  let l:new = {
    \ 'TYPE': {'SourceArguments': 1},
    \ 'source': {},
    \ 'sourceReference': 0,
  \ }
  return l:new
endfunction
