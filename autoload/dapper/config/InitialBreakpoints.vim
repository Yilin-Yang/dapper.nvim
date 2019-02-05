""
" @dict InitialBreakpoints
" Breakpoints to be set immediately after launching a debuggee process.

let s:typename = 'InitialBreakpoints'

""
" @dict InitialBreakpoints
" @function dapper#config#InitialBreakpoints#new([bps], [function_bps], [exception_bps])
" Return a new InitialBreakpoints object.
"
" [bps] should be a @dict(SetBreakpointsArguments); [function_bps] should be a
" @dict(SetFunctionBreakpointsArguments); [exception_bps] should be a
" @dict(SetExcepSetFunctionBreakpointsArguments). Each defaults to an empty
" dictionary if omitted.
"
" @throws WrongType if [bps], [function_bps], or [exception_bps] are not dictionaries.
function! dapper#config#InitialBreakpoints#new(...) abort
  let a:bps = maktaba#ensure#IsDict(get(a:000, 0, {}))
  let a:function_bps = maktaba#ensure#IsDict(get(a:000, 0, {}))
  let a:exception_bps = maktaba#ensure#IsDict(get(a:000, 0, {}))
  let l:new = {
    \ 'bps': a:bps,
    \ 'function_bps': a:function_bps,
    \ 'exception_bps': a:exception_bps,
  \ }
  return typevim#make#Class(s:typename, l:new)
endfunction
