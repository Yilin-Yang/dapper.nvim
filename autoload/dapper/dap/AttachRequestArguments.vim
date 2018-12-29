function! dapper#dap#AttachRequestArguments#new() abort
  let l:new = {
    \ 'TYPE': {'AttachRequestArguments': 1},
    \ '__restart': {},
  \ }
  return l:new
endfunction
