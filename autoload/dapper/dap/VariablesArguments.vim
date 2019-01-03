function! dapper#dap#VariablesArguments#new() abort
  let l:new = {
    \ 'TYPE': {'VariablesArguments': 1},
    \ 'variablesReference': 0,
    \ 'filter': '',
    \ 'start': 0,
    \ 'count': 0,
    \ 'format': {},
  \ }
  return l:new
endfunction

function! dapper#dap#VariablesArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'VariablesArguments')
  try
    let l:err = '(dapper#dap#VariablesArguments) Object is not of type VariablesArguments: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#VariablesArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
