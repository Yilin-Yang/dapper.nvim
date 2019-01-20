" BRIEF:  Basic startup configuration for a debug adapter.
" DETAILS:  `adapter_id` appears to be the value of `type` in `launch.json`.

" BRIEF:  Construct a new DebugAdapterConfig object.
" PARAM:  runtime_env   (v:t_string)  The environment in which to run the debug
"     adapter, e.g. `node`, `python3`.
" PARAM:  exe_filepath  (v:t_string)  The filepath of the debug adapter.
" PARAM:  adapter_id    (v:t_string)  Equivalent to the `type` attribute of a
"     `launch.json` file.
function! dapper#config#DebugAdapterConfig#new(
    \ runtime_env,
    \ exe_filepath,
    \ adapter_id,
    \ ) abort
  let l:new = {
    \ 'TYPE': {'DebugAdapterConfig': 1},
    \ 'runtime_env': a:runtime_env,
    \ 'exe_filepath': a:exe_filepath,
    \ 'adapter_id': a:adapter_id,
  \ }
  return l:new
endfunction

function! dapper#config#DebugAdapterConfig#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'DebugAdapterConfig')
  try
    let l:err = '(dapper#dap#DebugAdapterConfig) Object is not of type DebugAdapterConfig: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#dap#DebugAdapterConfig) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction
