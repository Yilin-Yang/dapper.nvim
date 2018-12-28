function! dapper#dap#Module() abort
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
