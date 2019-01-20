function! dapper#config#DapperConfig#new(attr, bps) abort
  call dapper#config#StartArgs#CheckType(a:attr)
  let l:new = {
    \ 'TYPE': {'DapperConfig': 1},
    \ 'attributes': a:attr,
    \ 'breakpoints': a:bps
  \ }
  return l:new
endfunction

function! dapper#config#DapperConfig#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'DapperConfig')
  try
    let l:err = '(dapper#dap#DapperConfig) Object is not of type DapperConfig: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#DapperConfig) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
