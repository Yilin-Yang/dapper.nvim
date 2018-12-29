function! dapper#config#StartArgs#new() abort
  let l:new = {
    \ 'TYPE': {'StartArgs': 1},
    \ 'runtime_env': '',
    \ 'exe_filepath': '',
    \ 'adapter_id': '',
    \ 'locale': '',
  \ }
  return l:new
endfunction

function! dapper#dap#StartArgs#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object['TYPE'], 'StartArgs')
    throw '(dapper#dap#StartArgs) Object is not of type StartArgs: ' . a:object
  endif
endfunction
