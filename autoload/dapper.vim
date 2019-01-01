" BRIEF:  Receive a response or event from the TypeScript middle-end.
function! dapper#receive(msg) abort
  call g:dapper_middletalker.receive(a:msg)
endfunction

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

" BRIEF:  Initialize and activate debug loggers of the given type(s).
" PARAM:  logger_type   (v:t_string|v:t_list)   The type(s) of logger to add.
" DETAILS:  See `dapper#log`, and `dapper#log#DebugLogger#log()` in
"           particular, for a list of valid logger_types.
function! dapper#AddDebugLogger(logger_type) abort
  let l:types = s:ConvertLoggerType(a:logger_type, 'AddDebugLogger')

  if !exists('g:dapper_report_handlers')
    let g:dapper_report_handlers = []
  endif

  let l:ddl = dapper#log#DebugLogger#get()
  let l:drh = g:dapper_report_handlers
  let l:dmt = g:dapper_middletalker
  let l:i = 0 | while l:i <# len(l:types)
    let l:type = l:types[l:i]
    if l:type ==# 'status'
      let l:to_add = dapper#log#StatusHandler#new(l:ddl, l:dmt)
    elseif l:type ==# 'error'
      let l:to_add = dapper#log#ErrorHandler#new(l:ddl, l:dmt)
    else
      throw '(dapper#AddDebugLogger) Unrecognized logger type: '.l:type
    endif
    let l:drh += [l:to_add]
  let l:i += 1 | endwhile
endfunction

" BRIEF:  Delete active debug loggers of the given type(s).
" PARAM:  logger_type   (v:t_string|v:t_list)   The type(s) of logger to clear.
" DETAILS:  See `dapper#log`, and `dapper#log#DebugLogger#log()` in
"           particular, for a list of valid logger_types.
let s:logger_types_to_typenames = {
    \ 'status': 'StatusHandler',
    \ 'error': 'ErrorHandler',
    \ 'ALL': 0,
    \ }
function! dapper#RemoveDebugLogger(logger_type) abort
  let l:types = s:ConvertLoggerType(a:logger_type, 'RemoveDebugLogger')
  if !exists('g:dapper_report_handlers')
    let g:dapper_report_handlers = []
    return
  endif

  let l:ddl = dapper#log#DebugLogger#get()
  let l:drh = g:dapper_report_handlers
  let l:dmt = dapper#MiddleTalker#get()

  let l:i = 0 | while l:i <# len(l:drh)
    let l:logger = l:drh[l:i]

    let l:j = 0 | while l:j <# len(l:types)
      let l:log_type = l:types[l:j]
      let l:typename = s:logger_types_to_typenames[l:log_type]
      if has_key(l:logger['TYPE'], l:typename) || l:log_type ==# 'ALL'
        call l:logger.destroy()
        unlet l:drh[l:i]
        break
      endif
    let l:j += 1 | endwhile

  let l:i += 1 | endwhile
endfunction
