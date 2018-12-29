function! dapper#config#DapperConfig#new(is_start, attr, bps) abort
  call dapper#config#StartArgs#CheckType(a:attr)
  let l:new = {
    \ 'TYPE': {'DapperConfig': 1},
    \ 'is_start': a:is_start,
    \ 'attributes': a:attr,
    \ 'breakpoints': a:bps
  \ }
  return l:new
endfunction

function! dapper#config#DapperConfig#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object['TYPE'], 'DapperConfig')
    throw '(dapper#dap#DapperConfig) Object is not of type DapperConfig: ' . a:object
  endif
endfunction
