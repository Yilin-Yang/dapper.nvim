function! dapper#dap#RestartFrameArguments() abort
  let l:new = {
    \ 'TYPE': {'RestartFrameArguments': 1},
    \ 'frameId': 0,
  \ }
  return l:new
endfunction
