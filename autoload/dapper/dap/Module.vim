function! dapper#dap#Module#new() abort
  let l:new = {
    \ 'TYPE': {'Module': 1},
    \ 'id': 0,
    \ 'name': '',
    \ 'path': '',
    \ 'isOptimized': 0,
    \ 'isUserCode': 0,
    \ 'version': '',
    \ 'symbolStatus': '',
    \ 'symbolFilePath': '',
    \ 'dateTimeStamp': '',
    \ 'addressRange': '',
  \ }
  return l:new
endfunction

function! dapper#dap#Module#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'Module')
  try
    let l:err = '(dapper#dap#Module) Object is not of type Module: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#Module) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
