function! dapper#dap#CompletionsArguments#new() abort
  let l:new = {
    \ 'TYPE': {'CompletionsArguments': 1},
    \ 'frameId': 0,
    \ 'text': '',
    \ 'column': 0,
    \ 'line': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#CompletionsArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'CompletionsArguments')
  try
    let l:err = '(dapper#dap#CompletionsArguments) Object is not of type CompletionsArguments: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#CompletionsArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
