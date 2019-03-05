""
" @public
" Checks if the given {level} corresponds to a valid maktaba notification
" level (see |maktaba#log#SetNotificationLevel|), or if {level} is the string
" "none". Returns {level} for convenience.
"
" @throws BadValue if {level} is not a valid notification level, or the string "none".
" @throws WrongType if {level} is not a string.
function! dapper#ensure#IsValidLogLevel(level) abort
  call maktaba#ensure#IsString(a:level)
  if a:level ==# dapper#constants#NO_LOGGING() | return a:level | endif
  return maktaba#ensure#IsIn(a:level, dapper#constants#LOG_LEVELS())
endfunction
