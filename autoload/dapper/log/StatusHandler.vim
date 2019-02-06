let s:name_pattern = 'StatusReport'

function! dapper#log#StatusHandler#new(logger, message_passer) abort
  let l:new = dapper#log#ReportHandler#new(a:logger)
  let l:new['TYPE']['StatusHandler'] = 1
  let l:new['DESTRUCTORS'] += [function('dapper#log#StatusHandler#destroy', l:new)]
  let l:new['__message_passer'] = a:message_passer
  let l:new['Receive'] = function('dapper#log#StatusHandler#Receive')
  call a:message_passer.Subscribe(s:name_pattern,
      \ function('dapper#log#StatusHandler#Receive', l:new))
  return l:new
endfunction

function! dapper#log#StatusHandler#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'StatusHandler')
  try
    let l:err = '(dapper#log#StatusHandler) Object is not of type StatusHandler: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#log#StatusHandler) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

function! dapper#log#StatusHandler#destroy() abort dict
  call dapper#log#StatusHandler#CheckType(l:self)
  call l:self['__message_passer'].Unsubscribe(
      \ s:name_pattern, function('dapper#log#StatusHandler#Receive', l:self))
endfunction

function! dapper#log#StatusHandler#Receive(msg) abort dict
  call dapper#log#StatusHandler#CheckType(l:self)
  call l:self._formatAndLog(a:msg, 'status')  " log to outfile

  " echo the message, if we should
  let l:to_echo = dapper#settings#EchoMessages()
  let l:should_echo = 0
  if l:to_echo ==# 'all_statuses'
    let l:should_echo = 1
  elseif l:to_echo ==# 'statuses' && a:msg['alert']
    let l:should_echo = 1
  endif
  if l:should_echo | call l:self._echoMsg(a:msg, 'None') | endif
endfunction
