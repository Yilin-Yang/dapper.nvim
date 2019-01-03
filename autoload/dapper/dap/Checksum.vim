function! dapper#dap#Checksum#new() abort
  let l:new = {
    \ 'TYPE': {'Checksum': 1},
    \ 'algorithm': {},
    \ 'checksum': '',
  \ }
  return l:new
endfunction

function! dapper#dap#Checksum#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Checksum')
  try
    let l:err = '(dapper#dap#Checksum) Object is not of type Checksum: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#Checksum) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
