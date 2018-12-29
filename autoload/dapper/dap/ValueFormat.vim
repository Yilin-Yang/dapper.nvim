function! dapper#dap#ValueFormat#new() abort
  let l:new = {
    \ 'TYPE': {'ValueFormat': 1},
    \ 'hex': v:false,
  \ }
  return l:new
endfunction
