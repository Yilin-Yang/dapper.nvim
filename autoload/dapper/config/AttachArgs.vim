function! dapper#dap#AttachArgs() abort
  let l:new = {
    \ 'TYPE': {'AttachArgs': 1},
    \ '__restart': {},
  \ }
  return l:new
endfunction
