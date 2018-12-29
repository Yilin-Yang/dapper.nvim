function! dapper#dap#ExceptionPathSegment#new() abort
  let l:new = {
    \ 'TYPE': {'ExceptionPathSegment': 1},
    \ 'negate': v:false,
    \ 'names': [],
  \ }
  return l:new
endfunction

function! dapper#dap#ExceptionPathSegment#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ExceptionPathSegment')
    throw '(dapper#dap#ExceptionPathSegment) Object is not of type ExceptionPathSegment: ' . string(a:object)
  endif
endfunction
