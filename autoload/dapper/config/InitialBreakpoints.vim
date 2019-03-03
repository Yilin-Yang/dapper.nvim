""
" @dict InitialBreakpoints
" Breakpoints to be set immediately after launching a debuggee process.

let s:typename = 'InitialBreakpoints'

" @public
" @dict InitialBreakpoints
" @function dapper#config#InitialBreakpoints#Interface()
function! dapper#config#InitialBreakpoints#Interface() abort
  if !exists('s:interface')
    let s:interface = {
        \ 'bps?': dapper#dap#SetBreakpointsArguments(),
        \ 'function_bps?': dapper#dap#SetFunctionBreakpointsArguments(),
        \ 'exception_bps?': dapper#dap#SetExceptionBreakpointsArguments(),
        \ }
    call typevim#make#Interface(s:typename, s:interface)
  endif
  return s:interface
endfunction

""
" @dict InitialBreakpoints
" @function dapper#config#InitialBreakpoints#New([bps], [function_bps], [exception_bps])
" Return a new InitialBreakpoints object.
"
" [bps] should be a @dict(SetBreakpointsArguments); [function_bps] should be a
" @dict(SetFunctionBreakpointsArguments); [exception_bps] should be a
" @dict(SetExcepSetFunctionBreakpointsArguments). Each defaults to an empty
" dictionary if omitted.
"
" @throws WrongType if [bps], [function_bps], or [exception_bps] are not dictionaries, or if they are nonempty but do not implement the appropriate interfaces.
function! dapper#config#InitialBreakpoints#New(...) abort
  let a:bps = maktaba#ensure#IsDict(get(a:000, 0, {}))
  let a:function_bps = maktaba#ensure#IsDict(get(a:000, 0, {}))
  let a:exception_bps = maktaba#ensure#IsDict(get(a:000, 0, {}))
  let l:new = {}
  if !empty(a:bps)
    call typevim#ensure#Implements(a:bps, dapper#dap#SetBreakpointsArguments())
    let l:new.bps = a:bps
  endif
  if !empty(a:function_bps)
    call typevim#ensure#Implements(
        \ a:bps, dapper#dap#SetFunctionBreakpointsArguments())
    let l:new.function_bps = a:function_bps
  endif
  if !empty(a:exception_bps)
    call typevim#ensure#Implements(
        \ a:bps, dapper#dap#SetExceptionBreakpointsArguments())
    let l:new.exception_bps = a:exception_bps
  endif
  return typevim#make#Class(s:typename, l:new)
endfunction
