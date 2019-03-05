""
" @dict DebuggeeArgs
" Arguments for starting the debuggee process.

let s:typename = 'DebuggeeArgs'

""
" @public
" @dict DebuggeeArgs
" @function dapper#config#DebuggeeArgs#Interface()
function! dapper#config#DebuggeeArgs#Interface() abort
  if !exists('s:interface')
    let s:interface = {
        \ 'request': ['launch', 'attach'],
        \ 'name': typevim#String(),
        \ 'args': [
            \ dapper#dap#LaunchRequestArguments(),
            \ dapper#dap#AttachRequestArguments()],
        \ 'initial_bps?': dapper#config#InitialBreakpoints#Interface(),
        \ }
    call typevim#make#Interface(s:typename, s:interface)
  endif
  return s:interface
endfunction

""
" @public
" @dict DebuggeeArgs
" Construct a DebuggeeArgs object.
"
" {request} is either `"launch"` or `"attach"`.
"
" {name} is a "human-friendly" name for this debug adapter configuration.
"
" {args} is either a DebugProtocol.LaunchRequestArguments (must be specified
" if {request} is `"launch"`), or a DebugProtocol.AttachRequestArguments (must
" be specified if {request} is `"attach"`).
"
" [initial_bps] is a struct of InitialBreakpoints to set immediately upon
" construction, or an empty dict (to signify that no initial breakpoints are
" being sent).
"
" @throws BadValue if {args} or [initial_bps] are not dictionaries.
" @throws WrongType if {request} or {name} aren't strings, if {args} does not implement one of the two interfaces as mentioned above, or if [initial_bps] is nonempty and not an InitialBreakpoints.
function! dapper#config#DebuggeeArgs#New(
    \ request, name, args, ...) abort
  call maktaba#ensure#IsString(a:request)
  call maktaba#ensure#IsString(a:name)
  if a:request ==# 'launch'
    call typevim#ensure#Implements(a:args, dapper#dap#LaunchRequestArguments())
  elseif a:request ==# 'attach'
    call typevim#ensure#Implements(a:args, dapper#dap#AttachRequestArguments())
  endif
  let l:initial_bps = maktaba#ensure#IsDict(get(a:000, 0, {}))

  let l:new = {
      \ 'request': a:request,
      \ 'name': a:name,
      \ 'args': a:args,
      \ }
  if !empty(l:initial_bps)
    call typevim#ensure#Implements(
        \ l:initial_bps, dapper#config#InitialBreakpoints#Interface())
    let l:new.initial_bps = l:initial_bps
  endif
  call typevim#make#Class(s:typename, l:new)
  return typevim#ensure#Implements(
      \ l:new, dapper#config#DebuggeeArgs#Interface())
endfunction
