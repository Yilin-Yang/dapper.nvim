function! dapper#dap#LoadedSourcesArguments#new() abort
  let l:new = {
    \ 'TYPE': {'LoadedSourcesArguments': 1},
  \ }
  return l:new
endfunction

function! dapper#dap#LoadedSourcesArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'LoadedSourcesArguments')
  try
    let l:err = '(dapper#dap#LoadedSourcesArguments) Object is not of type LoadedSourcesArguments: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#LoadedSourcesArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
