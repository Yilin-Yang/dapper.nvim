""
" @dict ReportHandler
" An object that subscribes to incoming @dict(Report)s and logs them for
" debugging purposes, sometimes displaying them to the user.

" BRIEF:  Construct a new ReportHandler object.
" PARAM:  logger  (dapper#DebugLogger)  The interface used to log reports.
" PARAM:  message_passer  (dapper#MiddleTalker) The interface from which the
"             ReportHandler should receive reports and other messages.
" PARAM:  pattern (v:t_string)  A string-match regex pattern to match against
"             the `vim_msg_typename` of incoming messages.
function! dapper#log#ReportHandler#new(logger) abort
  let l:new = {
      \ 'TYPE': {'ReportHandler': 1},
      \ 'DESTRUCTORS': [],
      \ 'destroy': function('dapper#log#ReportHandler#destroy'),
      \ '___logger___': a:logger,
      \ 'receive': function('dapper#log#ReportHandler#receive'),
      \ '_echoMsg': function('dapper#log#ReportHandler#_echoMsg'),
      \ '_formatAndLog': function('dapper#log#ReportHandler#_formatAndLog'),
      \ '_logReport': function('dapper#log#ReportHandler#_logReport'),
      \ }
  return l:new
endfunction

function! dapper#log#ReportHandler#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ReportHandler')
  try
    let l:err = '(dapper#log#ReportHandler) Object is not of type ReportHandler: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#log#ReportHandler) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

function! dapper#log#ReportHandler#__noImpl(func_name, ...) abort dict
  throw '(dapper#log#ReportHandler) Invoked pure virtual function: '.a:func_name
endfunction

function! dapper#log#ReportHandler#destroy() abort dict
  call dapper#log#ReportHandler#CheckType(l:self)
  let l:dtors = l:self['DESTRUCTORS']
  let l:i = len(l:dtors) - 1 | while l:i >=# 0
    let l:Dtor = l:dtors[l:i]
    call function(l:Dtor, l:self)
  let l:i -= 1 | endwhile
endfunction

" BRIEF:  Process an incoming message, potentially writing it to the log.
function! dapper#log#ReportHandler#receive(msg) abort dict
  call dapper#log#ReportHandler#CheckType(l:self)
  call dapper#log#ReportHandler#__noImpl('receive')
endfunction

" BRIEF:  Echo a message to the user, if configured to do so.
" PARAM:  msg   (DapperReport)
" PARAM:  hl    (v:t_string)    The highlight group to apply to the message.
function! dapper#log#ReportHandler#_echoMsg(msg, hl) abort dict
  call dapper#log#ReportHandler#CheckType(l:self)
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
  call dapper#log#ReportHandler#CheckType(l:self)
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
  call dapper#log#ReportHandler#CheckType(l:self)
  call l:self['___logger___'].log(a:text, a:type)
endfunction
