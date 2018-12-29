function! dapper#dap#ExceptionPathSegment#new() abort
  let l:new = {
    \ 'TYPE': {'ExceptionPathSegment': 1},
    \ 'negate': v:false,
    \ 'names': [],
  \ }
  return l:new
endfunction
