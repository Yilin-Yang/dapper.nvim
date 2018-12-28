function! dapper#dap#AttachRequestArguments() abort
  let l:new = {
    \ 'TYPE': {'AttachRequestArguments': 1},
    \ '__restart': {},
  \ }
  return l:new
endfunction
