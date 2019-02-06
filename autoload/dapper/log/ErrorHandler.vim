" BRIEF:  Logs error messages, showing some of them as messages.
let s:name_pattern = 'ErrorReport'

function! dapper#log#ErrorHandler#new(logger, message_passer) abort
  let l:new = dapper#log#ReportHandler#new(a:logger)
  let l:new['TYPE']['ErrorHandler'] = 1
  let l:new['DESTRUCTORS'] += [function('dapper#log#ErrorHandler#destroy', l:new)]
  let l:new['__message_passer'] = a:message_passer
  let l:new['Receive'] = function('dapper#log#ErrorHandler#Receive')
  call a:message_passer.Subscribe(s:name_pattern,
      \ function('dapper#log#ErrorHandler#Receive', l:new))
  return l:new
endfunction

function! dapper#log#ErrorHandler#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'ErrorHandler')
  try
    let l:err = '(dapper#log#ErrorHandler) Object is not of type ErrorHandler: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#log#ErrorHandler) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

function! dapper#log#ErrorHandler#destroy() abort dict
  call dapper#log#ErrorHandler#CheckType(l:self)
  call l:self['__message_passer'].Unsubscribe(
      \ s:name_pattern, function('dapper#log#ErrorHandler#Receive', l:self))
endfunction

function! dapper#log#ErrorHandler#Receive(msg) abort dict
  call dapper#log#ErrorHandler#CheckType(l:self)
  call l:self._formatAndLog(a:msg, 'error')  " log to outfile

  " echo the message, if we should
  let l:to_echo = dapper#settings#EchoMessages()
  let l:should_echo = 0
  if match(l:to_echo, 'all_') !=# -1 || l:to_echo ==# 'statuses'
    let l:should_echo = 1
  elseif l:to_echo ==# 'only_errors' && a:msg['alert']
    let l:should_echo = 1
  endif
  if l:should_echo | call l:self._echoMsg(a:msg, 'WarningMsg') | endif
endfunction
