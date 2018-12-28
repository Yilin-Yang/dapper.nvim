function! dapper#dap#DapperConfig(is_start, attr, bps) abort
  let l:new = {
    \ 'TYPE': {'DapperConfig': 1},
    \ 'is_start': v:false,
    \ 'attributes': {},
    \ 'breakpoints': {}
  \ }
  return l:new
endfunction
