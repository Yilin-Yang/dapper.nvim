" BRIEF:  Represent exception types on which to break.

" BRIEF:  Construct a new ExceptionBreakpoints object.
" PARAM:  filters     (dapper#model#Model)
" PARAM:  msg_passer  (dapper#MiddleTalker)
function! dapper#model#ExceptionBreakpoints#new(filters, msg_passer, ...) abort
  if type(a:filters) !=# v:t_dict
    throw 'ERROR(WrongType) (dapper#model#ExceptionBreakpoints) Filters must be '
        \ .'given as dict: '.dapper#helpers#StrDump(a:filters)
  endif
  let l:new = call('dapper#model#Breakpoints#new', [a:msg_passer] + a:000)
  let l:new['TYPE']['ExceptionBreakpoints'] = 1
  let l:new['_filters'] = a:filters

  " monkey-patch a friendlier setBreakpoint interface
  let l:new['Breakpoints#setBreakpoint'] = l:new['setBreakpoint']
  let l:new['setBreakpoint'] =
      \ function('dapper#dap#ExceptionBreakpoint#setBreakpoint')

  let l:new['_matchOn']     = { -> 'filter'}
  let l:new['_matchOnType'] = { -> v:t_string}
  let l:new['_command']     = { -> 'setExceptionBreakpoints'}
  let l:new['_bpCtor']      = function('dapper#dap#ExceptionBreakpoint#new')

  let l:new['_argsFromSelf'] =
      \ function('dapper#model#ExceptionBreakpoints#_argsFromSelf')

  call a:msg_passer.subscribe('SetExceptionBreakpointsResponse',
      \ function('dapper#model#Breakpoints#receive', l:new))

  return l:new
endfunction

function! dapper#model#ExceptionBreakpoints#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ExceptionBreakpoints')
  try
    let l:err = '(dapper#model#ExceptionBreakpoints) Object is not of type ExceptionBreakpoints: '.string(a:object)
  catch
    redir => l:object
    echo a:object
    redir end
    let l:err = '(dapper#model#ExceptionBreakpoints) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" BRIEF:  Set or modify an exception breakpoint.
" PARAM:  props (dapper#dap#ExceptionBreakpoint)  The properties of the
"     breakpoint.
let s:break_modes = ['never', 'always', 'unhandled', 'userUnhandled']
function! dapper#model#ExceptionBreakpoints#setBreakpoint(props) abort dict
  call dapper#model#ExceptionBreakpoints#CheckType(l:self)
  if type(a:props) !=# v:t_dict || !has_key(a:props, 'filter')
      \ || !has_key(a:props, 'exceptionOptions')
    throw 'ERROR(BadValue) (dapper#model#ExceptionBreakpoints) Malformed '
        \ . 'props: '.dapper#helpers#StrDump(a:props)
  endif
  let a:filter = a:props['filter']
  let a:opts   = a:props['exceptionOptions']
  if type(a:filter) !=# v:t_string
    throw 'ERROR(WrongType) (dapper#model#ExceptionBreakpoints) Filter must be '
        \ . 'string: '.dapper#helpers#StrDump(a:filter)
  endif
  if type(a:opts) !=# v:t_dict || !has_key(a:opts, 'breakMode')
    throw 'ERROR(BadValue) (dapper#model#ExceptionBreakpoints) '
        \ . 'Malformed ExceptionOptions: '.dapper#helpers#StrDump(a:opts)
  endif
  let l:supported_filters = l:self['_filters']
  if !has_key(l:supported_filters, a:filter) || !l:supported_filters[a:filter]
    call l:self['__message_passer'].notifyReport(
        \ 'error',
        \ 'Unsupported exception filter: '.a:filter,
        \ a:props,
        \ v:true
        \ )
    return
  endif
  let l:br_mode = a:opts['breakMode']
  if index(s:break_modes, l:br_mode) ==# -1
    throw 'ERROR(BadValue) (dapper#model#ExceptionBreakpoints) '
        \ . 'Invalid break mode: '.dapper#helpers#StrDump(l:br_mode)
  endif
  call l:self['Breakpoints#setBreakpoint'](a:props)
endfunction

function dapper#model#ExceptionBreakpoints#_argsFromSelf() abort dict
  call dapper#model#ExceptionBreakpoints#CheckType(l:self)
  let l:bps = l:self['_bps']
  let l:args = dapper#dap#SetExceptionBreakpointsArguments#new()
  for l:bp in l:bps
     call add(l:args['filters'], l:bps['filter'])
     call add(l:args['exceptionOptions'], l:bps['exceptionOptions'])
  endfor
  return l:args
endfunction
