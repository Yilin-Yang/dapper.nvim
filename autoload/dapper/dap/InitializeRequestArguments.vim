function! dapper#dap#InitializeRequestArguments() abort
  let l:new = {
    \ 'TYPE': {'InitializeRequestArguments': 1},
    \ 'clientID': '',
    \ 'clientName': '',
    \ 'adapterID': '',
    \ 'locale': '',
    \ 'linesStartAt1': v:true,
    \ 'columnsStartAt1': v:true,
    \ 'pathFormat': '',
    \ 'supportsVariableType': v:true,
    \ 'supportsVariablePaging': v:true,
    \ 'supportsRunInTerminalRequest': v:true,
  \ }
  return l:new
endfunction
