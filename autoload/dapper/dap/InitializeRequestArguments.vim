function! dapper#dap#InitializeRequestArguments#new() abort
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

function! dapper#dap#InitializeRequestArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'InitializeRequestArguments')
    throw '(dapper#dap#InitializeRequestArguments) Object is not of type InitializeRequestArguments: ' . string(a:object)
  endif
endfunction
