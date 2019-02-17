""
" @private
" @dict DebugLogger
" A global debug logger. Writes incoming @dict(Report)s to a log buffer and,
" optionally, a logfile.

let s:typename = 'DebugLogger'

""
" @dict DebugLogger
" Returns the interface that DebugLogger implements.
function! dapper#log#DebugLogger#Interface() abort
  if !exists('s:interface')
    let s:interface = {
        \ 'Log': typevim#Func(),
        \ 'NotifyReport': typevim#Func(),
        \ }
    call typevim#make#Interface(s:typename, s:interface)
  endif
  return s:interface
endfunction
