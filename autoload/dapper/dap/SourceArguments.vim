function! dapper#dap#SourceArguments#new() abort
  let l:new = {
    \ 'TYPE': {'SourceArguments': 1},
    \ 'source': {},
    \ 'sourceReference': 0,
  \ }
  return l:new
endfunction

function! dapper#dap#SourceArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'SourceArguments')
  try
    let l:err = '(dapper#dap#SourceArguments) Object is not of type SourceArguments: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#dap#SourceArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
