""
" @dict ReportHandler
" An object that subscribes to incoming @dict(Report)s and logs them for
" debugging purposes, sometimes displaying them to the user.

let s:typename = 'ReportHandler'

""
" @public
" Construct a new ReportHandler object.
"
" {logger} is the interface used to log reports, e.g. a @dict(DebugLogger)
" object.
"
" @throws WrongType if {logger} is not a dictionary.
function! dapper#log#ReportHandler#new(logger) abort
  let l:new = {
      \ 'TYPE': {'ReportHandler': 1},
      \ '___logger___': a:logger,
      \ 'Receive': typevim#make#Member('Receive'),
      \ '_echoMsg': typevim#make#Member('_echoMsg'),
      \ '_formatAndLog': typevim#make#Member('_formatAndLog'),
      \ '_logReport': typevim#make#Member('_logReport'),
      \ }
  return typevim#make#Class(s:typename, l:new)
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @dict ReportHandler
" @public
" Process an incoming message, potentially writing it to the debug logger.
" @throws WrongType if {msg} is not a dictionary.
function! dapper#log#ReportHandler#Receive(msg) abort dict
  call s:CheckType(l:self)
  call dapper#log#ReportHandler#__noImpl('receive')
endfunction

""
" Echo a {msg} to the user using highlight group {hl}, if configured to do so.
"
" @throws WrongType if {msg} is not a dictionary, or if {hl} is not a stirng.
function! dapper#log#ReportHandler#_echoMsg(msg, hl) abort dict
  call s:CheckType(l:self)
  call maktaba#ensure#IsDict(a:msg)
  call maktaba#ensure#IsString(a:hl)
  let l:verbosity = dapper#settings#EchoMessageVerbosity()
  if dapper#settings#RedrawOnEcho()
    redraw  " most recent echo will clobber those before
  endif
  execute 'echohl '.a:hl
  if l:verbosity ==# 'kind'
    echomsg '(dapper.nvim) Received update of kind: '.a:msg['kind']
  elseif l:verbosity ==# 'brief'
    let l:to_print = '(DAP#'.a:msg['kind'].') '.a:msg['brief']
    " truncate message to show without triggering a hit-enter prompt
    let l:to_print = l:to_print[0 : winwidth(0) - 20]
    echomsg l:to_print
  elseif l:verbosity ==# 'long'
    let l:to_print = '(dapper.nvim) Received update ('.a:msg['kind'].'): '
        \ . a:msg['long']
    echomsg l:to_print
  elseif l:verbosity ==# 'everything'
    let l:to_print = '(dapper.nvim) Received update ('.a:msg['kind'].'): '
        \ . a:msg['brief']."\n"
        \ . a:msg['long']."\n"
        \ . 'Alert: '.a:msg['alert']
    if has_key(a:msg, 'other')
      let l:to_print .= "\nOther:".string(a:msg['other'])
    endif
    echo l:to_print
  endif
  echohl None
endfunction

" BRIEF:  Convenience function; parse a Report and then call `_logReport`.
" PARAM:  msg   (DapperReport)  The Report to log.
function! dapper#log#ReportHandler#_formatAndLog(msg, type) abort dict
  call s:CheckType(l:self)
  let l:lines = [
      \ 'BRIEF: '.typevim#object#ShallowPrint(a:msg['brief']),
      \ 'LONG:  '.typevim#object#ShallowPrint(a:msg['long']),
      \ 'ALERT: '.typevim#object#ShallowPrint(a:msg['alert']),
      \ ]
  if has_key(a:msg, 'other')
    let l:lines += [
      \ 'OTHER: '.typevim#object#ShallowPrint(a:msg['other']),
      \ ]
  endif
  call l:self._logReport(l:lines, a:type)
endfunction

" BRIEF:  Write a report to the output log.
" DETAILS:  Shall have the same function signature as `DebugLogger::log`.
function! dapper#log#ReportHandler#_logReport(text, type) abort dict
  call s:CheckType(l:self)
  call l:self['___logger___'].log(a:text, a:type)
endfunction
