function! dapper#dap#Terminaterguments#new() abort
  let l:new = {
    \ 'TYPE': {'TerminateArguments': 1},
    \ 'restart': v:false,
  \ }
  return l:new
endfunction
