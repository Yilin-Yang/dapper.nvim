" BRIEF:  Add a configuration for a particular debug adapter.
" DETAILS:  For example, to add `vscode-node-debug2`, a debug adapter for
"           Node.js applications,
"             call dapper#AddDapperConfig#(
"               \ 'node',
"               \ '/home/yourname/.vim/bundle/dapper.nvim/'
"                 \ .'adapters/vscode-node-debug2/out/src/nodeDebug.js',
"               \ 'node')
"
function! dapper#AddDapperConfig(runtime_env, exe_filepath, adapter_id, ...) abort
  let l:args = [a:runtime_env, a:exe_filepath, a:adapter_id]
  " handle locale
  let a:locale = a:0 ? [ a:1 ] : []
  let l:args += a:locale
  let l:cfg = call('dapper#config#StartArgs#new', l:args)
  " TODO: handle multiple adapter types for a single filetype,
  "       e.g. Node.js and Angular for filetype=javascript
  let l:fts_to_cfgs = dapper#settings#FiletypesToConfigs()
  let l:fts_to_cfgs[a:adapter_id] = l:cfg
endfunction

" BRIEF:  Receive a response or event from the TypeScript middle-end.
function! dapper#receive(msg) abort
  call g:dapper_middletalker.receive(a:msg)
endfunction
