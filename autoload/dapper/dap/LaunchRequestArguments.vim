function! dapper#dap#LaunchRequestArguments#new() abort
  let l:new = {
    \ 'TYPE': {'LaunchRequestArguments': 1},
    \ 'noDebug': v:false,
    \ '__restart': {},
  \ }
  return l:new
endfunction

function! dapper#dap#LaunchRequestArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'LaunchRequestArguments')
  try
    let l:err = '(dapper#dap#LaunchRequestArguments) Object is not of type LaunchRequestArguments: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#LaunchRequestArguments) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
