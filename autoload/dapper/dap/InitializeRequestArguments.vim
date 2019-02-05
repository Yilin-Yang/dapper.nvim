function! dapper#dap#InitializeRequestArguments#new() abort
  let l:new = {
    \ 'TYPE': {'InitializeRequestArguments': 1},
    \ 'clientID': '',
    \ 'clientName': '',
    \ 'adapterID': '',
    \ 'locale': '',
    \ 'linesStartAt1': 1,
    \ 'columnsStartAt1': 1,
    \ 'pathFormat': '',
    \ 'supportsVariableType': 1,
    \ 'supportsVariablePaging': 1,
    \ 'supportsRunInTerminalRequest': 1,
  \ }
  return l:new
endfunction

function! dapper#dap#InitializeRequestArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'InitializeRequestArguments')
  try
    let l:err = '(dapper#dap#InitializeRequestArguments) Object is not of type InitializeRequestArguments: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#InitializeRequestArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
