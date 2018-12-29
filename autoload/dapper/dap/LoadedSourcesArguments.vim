function! dapper#dap#LoadedSourcesArguments#new() abort
  let l:new = {
    \ 'TYPE': {'LoadedSourcesArguments': 1},
  \ }
  return l:new
endfunction

function! dapper#dap#LoadedSourcesArguments#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'LoadedSourcesArguments')
    throw '(dapper#dap#LoadedSourcesArguments) Object is not of type LoadedSourcesArguments: ' . string(a:object)
  endif
endfunction
