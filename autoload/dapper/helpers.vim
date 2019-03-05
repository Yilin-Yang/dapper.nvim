""
" @public
" @function dapper#helpers#LevelToNum(level)
" Converts the given maktaba notification level (see
" |maktaba#log#SetNotificationLevel|) to a numerical value. "Lower"
" notification levels have lower numerical values than "higher" levels, e.g.
" "debug" corresponds to a lower value than "info", which has a lower value
" than "warn".
"
" {level} may also be "none", which returns a numerical value larger than all
" "true" notification levels.
"
" @throws BadValue if {level} is a string but is not a maktaba notification level.
" @throws WrongType if {level} is not a string.
function! dapper#helpers#LevelToNum(level) abort
  call maktaba#ensure#IsString(a:level)
  if a:level ==# dapper#constants#NO_LOGGING()
    return 999  " arbitrary large number
  endif
  let l:idx = index(dapper#constants#LOG_LEVELS(), a:level)
  if l:idx ==# -1
    throw maktaba#error#BadValue(
        \ 'String is not a maktaba notification level: %s', a:level)
  endif
  return l:idx
endfunction
