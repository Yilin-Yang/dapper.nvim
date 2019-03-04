""
" @section Introduction, intro
" @stylized dapper.nvim
" A neovim frontend for Microsoft's Debug Adapter Protocol, or, a concerted
" effort to take the best features of Microsoft's VSCode test editor and
" crudely staple them onto neovim.

""
" @public
" Receive a response or event from the TypeScript middle-end.
function! dapper#receive(msg) abort
  try
    call g:dapper_middletalker.Receive(a:msg)
  catch
    call g:dapper_middletalker.NotifyReport(
        \ 'error',
        \ 'Receiving message from middle-end threw exception!',
        \ 'Threw: "'.v:exception.'" from throwpoint: '.v:throwpoint,
        \ a:msg
        \ )
    throw v:exception.', from '.v:throwpoint
  endtry
endfunction

" BRIEF:  Add a configuration for a particular debug adapter.
" DETAILS:  For example, to add `vscode-node-debug2`, a debug adapter for
"           Node.js applications,
"             call dapper#AddDapperConfig#(
"               \ 'node',
"               \ '/home/yourname/.vim/bundle/dapper.nvim/'
"                 \ .'adapters/vscode-node-debug2/out/src/nodeDebug.js',
"               \ 'node')
" PARAM:  adapter_id  (v:t_string)  The name of the debug adapter.
" PARAM:  filetype    (v:t_string)  The filetype associated with the adapter,
"     as would be reported by `:echo &filetype`.
" PARAM:  locale  (v:t_string?)   Defaults to the `v:ctype` of vim, i.e. the
"     user's current locale.
function! dapper#AddDapperConfig(
    \ runtime_env, exe_filepath, adapter_id, filetype, ...) abort
  let l:args = [a:runtime_env, a:exe_filepath, a:adapter_id]

  " handle locale
  let a:locale = a:0 ? [ a:1 ] : []
  let l:args += a:locale

  " check argument types
  if type(a:runtime_env) !=# v:t_string
      \ || type(a:exe_filepath) !=# v:t_string
      \ || type(a:adapter_id) !=# v:t_string
      \ || type(a:filetype) !=# v:t_string
      \ || (!empty(a:locale) && type(a:locale[0]) !=# v:t_string)
    throw 'ERROR(WrongType) (dapper#AddDapperConfig) All given arguments must '
        \ . 'be strings. Gave: '
            \ . typevim#object#ShallowPrint(a:runtime_env)  . ', '
            \ . typevim#object#ShallowPrint(a:exe_filepath) . ', '
            \ . typevim#object#ShallowPrint(a:adapter_id)   . ', '
            \ . typevim#object#ShallowPrint(a:filetype)
            \ . a:0 ? a:1 : ''
  endif

  let l:new_cfg = call('dapper#config#DebugAdapterConfig#New', l:args)

  let l:fts_to_cfgs = dapper#settings#FiletypesToConfigs()
  if !has_key(l:fts_to_cfgs, a:filetype)
    let l:fts_to_cfgs[a:filetype] = {}
  endif
  let l:cfgs = l:fts_to_cfgs[a:filetype]
  let l:cfgs[a:adapter_id] = l:new_cfg
endfunction

function! s:ConvertLoggerType(logger_type, funcname) abort
  let l:argtype = type(a:logger_type)
  if l:argtype !=# v:t_string && l:argtype !=# v:t_list
    throw '(dapper#'.a:funcname.') Bad argument type for arg: '.a:logger_type
  endif
  if l:argtype ==# v:t_string
    let l:types = [a:logger_type]
  else
    let l:types = a:logger_type
  endif
  return l:types
endfunction
