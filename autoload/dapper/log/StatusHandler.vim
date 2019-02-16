let s:typename = 'StatusHandler'
let s:name_pattern = 'StatusReport'

function! dapper#log#StatusHandler#New(logger, message_passer) abort
  let l:base = dapper#log#ReportHandler#New(a:logger)
  let l:new = {
      \ '__message_passer': a:message_passer,
      \ 'Receive': typevim#make#Member('Receive'),
      \ }
  call typevim#make#Derived(
      \ s:typename, l:base, l:new, typevim#make#Member('CleanUp'))
  let l:new.Receive = typevim#object#Bind(l:new.Receive, l:new)
  call a:message_passer.Subscribe(s:name_pattern, l:new.Receive)
  return l:new
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

function! dapper#log#StatusHandler#CleanUp() abort dict
  call s:CheckType(l:self)
  call l:self['__message_passer'].Unsubscribe(s:name_pattern, l:self.Receive)
endfunction

function! dapper#log#StatusHandler#Receive(msg) abort dict
  call s:CheckType(l:self)
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
