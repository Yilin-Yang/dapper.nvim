""
" @dict DebugAdapterConfig
" Basic startup configuration for a debug adapter.
"
" `adapter_id` appears to be the value of `type` in `launch.json`.

let s:typename = 'DebugAdapterConfig'

""
" @public
" @dict DebugAdapterConfig
" @function dapper#config#DebugAdapterConfig#new({runtime_env} {exe_filepath} {adapter_id)
" Construct a new DebugAdapterConfig object.
"
" {runtime_env} is the environment in which to run the debug adapter, e.g.
" `"node"`, `"python3"`.
"
" {exe_filepath} is the filepath of the debug adapter.
"
" {adapter_id} is equivalent to the `type` attribute of a `launch.json` file.
"
" @throws WrongType if any of the arguments above are not strings.
function! dapper#config#DebugAdapterConfig#new(
    \ runtime_env,
    \ exe_filepath,
    \ adapter_id) abort
  call maktaba#ensure#IsString(a:runtime_env)
  call maktaba#ensure#IsString(a:exe_filepath)
  call maktaba#ensure#IsString(a:adapter_id)
  let l:new = {
    \ 'runtime_env': a:runtime_env,
    \ 'exe_filepath': a:exe_filepath,
    \ 'adapter_id': a:adapter_id,
  \ }
  return typevim#make#Class(s:typename, l:new)
endfunction
