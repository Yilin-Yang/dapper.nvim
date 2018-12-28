function! dapper#dap#ValueFormat() abort
  let l:new = {
    \ 'TYPE': {'ValueFormat': 1},
    \ 'hex': v:false,
  \ }
  return l:new
endfunction
