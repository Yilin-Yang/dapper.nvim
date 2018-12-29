function! dapper#dap#Module#new() abort
  let l:new = {
    \ 'TYPE': {'Module': 1},
    \ 'id': 0,
    \ 'name': '',
    \ 'path': '',
    \ 'isOptimized': v:false,
    \ 'isUserCode': v:false,
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
    throw '(dapper#dap#Module) Object is not of type Module: ' . string(a:object)
  endif
endfunction
