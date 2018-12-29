function! dapper#config#DapperConfig#new(is_start, attr, bps) abort
  call dapper#dap#StartArgs#CheckType(a:attr)
  call dapper#dap#InitialBreakpoints#CheckType(a:bps)
  let l:new = {
    \ 'TYPE': {'DapperConfig': 1},
    \ 'is_start': a:is_start,
    \ 'attributes': a:attr,
    \ 'breakpoints': a:bps
  \ }
  return l:new
endfunction

function! dapper#dap#DapperConfig#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object['TYPE'], 'DapperConfig')
    throw '(dapper#dap#DapperConfig) Object is not of type DapperConfig: ' . a:object
  endif
endfunction
