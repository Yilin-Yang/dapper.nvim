function! dapper#dap#Terminaterguments() abort
  let l:new = {
    \ 'TYPE': {'TerminateArguments': 1},
    \ 'restart': v:false,
  \ }
  return l:new
endfunction
