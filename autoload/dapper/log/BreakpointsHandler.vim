" BRIEF:  If breakpoints couldn't be set, emit an `ErrorReport`.
" DETAILS:  It is intended that emitted `ErrorReport`s be handled by an
"     `ErrorHandler`.

let s:name_pattern='Set\%(Function\)\{-}BreakpointsResponse'

function! dapper#log#BreakpointsHandler#new(logger, message_passer) abort
  let l:new = dapper#log#ReportHandler#new(a:logger)
  let l:new['TYPE']['BreakpointsHandler'] = 1
  let l:new['DESTRUCTORS'] += [function('dapper#log#BreakpointsHandler#destroy', l:new)]
  let l:new['__message_passer'] = a:message_passer
  let l:new['receive'] = function('dapper#log#BreakpointsHandler#receive')
  let l:new['_reportSuccess'] =
      \ function('dapper#log#BreakpointsHandler#_reportSuccess')
  call a:message_passer.subscribe(s:name_pattern,
      \ function('dapper#log#BreakpointsHandler#receive', l:new))
  return l:new
endfunction

function! dapper#log#BreakpointsHandler#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'BreakpointsHandler')
  try
    let l:err = '(dapper#log#BreakpointsHandler) Object is not of type BreakpointsHandler: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#log#BreakpointsHandler) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

function! dapper#log#BreakpointsHandler#destroy() abort dict
  call dapper#log#BreakpointsHandler#CheckType(l:self)
  call l:self['__message_passer'].unsubscribe(
      \ s:name_pattern, function('dapper#log#BreakpointsHandler#receive', l:self))
endfunction

function! dapper#log#BreakpointsHandler#_reportSuccess(msg) abort dict
  call dapper#log#BreakpointsHandler#CheckType(l:self)
  call l:self['__message_passer'].notifyReport(
      \ 'status', 'Set breakpoints successfully.', a:msg)
endfunction

function! dapper#log#BreakpointsHandler#receive(msg) abort dict
  call dapper#log#BreakpointsHandler#CheckType(l:self)
  if !has_key(a:msg['body'], 'breakpoints')
    call l:self._reportSuccess(a:msg)
    return
  endif
  let l:bps = a:msg['body']['breakpoints']
  let l:failed = []
  for l:bp in l:bps
    if !l:bp['verified'] | call add(l:failed, l:bp) | endif
  endfor
  if empty(l:failed)
    call l:self._reportSuccess(a:msg)
  elseif len(l:failed) ==# 1
    call l:self['__message_passer'].notifyReport(
        \ 'error', 'Failed to set breakpoint. ', l:failed[0], v:true)
  else
    call l:self['__message_passer'].notifyReport(
        \ 'error', 'Failed to set multiple breakpoints. ', l:failed, v:true)
  endif
endfunction
