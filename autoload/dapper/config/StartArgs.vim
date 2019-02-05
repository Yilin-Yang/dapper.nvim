""
" @dict StartArgs
" All arguments supplied to the middle-end. When provided in a call to
" @function(DapperStart), starts a debug adapter and a debuggee.

let s:typename = 'StartArgs'

""
" @dict StartArgs
" @function dapper#config#StartArgs#new({adapter_config}, {debuggee_args}, {vscode_attr}, [locale])
" Construct and return new StartArgs object.
"
" {adapter_config} is a @dict(DebugAdapterConfig) object, acting as
" configuration for the debug adapter itself.
"
" {debuggee_args} is a @dict(DebuggeeArgs) object: the debug adapter reads
" this, and uses it to launch or attach to a debugger process.
"
" {vscode_attr} is a @dict(VSCodeAttributes) object, or a basic dictionary: it
" contains other attributes from a `.vscode/launch.json` file used
" specifically by VSCode itself.
"
" [locale] is a string containing the ISO-639 locale of the neovim frontend,
" e.g. `en_US`.
"
" @throws WrongType if any of the arguments mentioned above are not of the specified types.
function! dapper#config#StartArgs#new(
    \ adapter_config, debuggee_args, vscode_attr, ...) abort
  call typevim#ensure#IsType(a:adapter_config, 'DebugAdapterConfig')
  call typevim#ensure#IsType(a:debuggee_args, 'DebuggeeArgs')
  call typevim#ensure#IsType(a:vscode_attr, 'VSCodeAttributes')
  " read default locale from v:ctype, trimming, e.g. '.UTF8'
  let a:locale = maktaba#ensure#IsString(get(a:000, 0, split(v:ctype, '\.')[0]))
  let l:new = {
      \ 'adapter_config': a:adapter_config,
      \ 'debuggee_args': a:debuggee_args,
      \ 'vscode_attr': a:vscode_attr,
      \ 'locale': a:locale
      \ }
  return typevim#make#Class(s:typename, l:new)
endfunction
