function! dapper#dap#LaunchRequestArguments() abort
  let l:new = {
    \ 'TYPE': {'LaunchRequestArguments': 1},
    \ 'noDebug': v:false,
    \ '__restart': {},
  \ }
  return l:new
endfunction