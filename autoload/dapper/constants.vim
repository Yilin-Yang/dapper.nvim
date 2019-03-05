""
" Returns the string constant used to represent a log level of "don't log
" anything."
function! dapper#constants#NO_LOGGING() abort
  return 'no_logging'
endfunction

""
" Returns, in ascending order of "value", all notification levels used by
" vim-maktaba. The returned list does not include the string "none".
function! dapper#constants#LOG_LEVELS() abort
  if !exists('s:log_levels')
    let s:log_levels = ['debug', 'info', 'warn', 'error', 'severe']
    lockvar! s:log_levels
  endif
  return s:log_levels
endfunction
