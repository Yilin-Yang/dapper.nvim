function! dapper#config#StartArgs#new(
    \ runtime_env,
    \ exe_filepath,
    \ adapter_id,
    \ ...) abort
  let l:default_locale = split(v:ctype, '\.')[0]
  let a:locale = get(a:000, 0, l:default_locale)
  let l:new = {
    \ 'TYPE': {'StartArgs': 1},
    \ 'runtime_env': a:runtime_env,
    \ 'exe_filepath': a:exe_filepath,
    \ 'adapter_id': a:adapter_id,
    \ 'locale': a:locale,
  \ }
  return l:new
endfunction

function! dapper#dap#StartArgs#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object['TYPE'], 'StartArgs')
    throw '(dapper#dap#StartArgs) Object is not of type StartArgs: ' . a:object
  endif
endfunction
