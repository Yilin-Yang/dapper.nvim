""
" @dict DebuggeeArgs
" Arguments for starting the debuggee process.

let s:typename = 'DebuggeeArgs'

""
" @public
" @dict DebuggeeArgs
" @function dapper#config#DebuggeeArgs#New({request} {name} {args})
" Construct a DebuggeeArgs object.
"
" {request} is either `"launch"` or `"attach"`.
"
" {name} is a "human-friendly" name for this debug adapter configuration.
"
" {args} is either an @dict(LaunchRequestArguments) or an
" @dict(AttachRequestArguments): it consists of other arguments to provide to
" the debug adapter, to start a debugger/debuggee or attach to a preexisting
" one.
"
" @throws WrongType if {request} or {name} aren't strings, or if {args} is not a dictionary.
function! dapper#config#DebuggeeArgs#New(
    \ request,
    \ name,
    \ args) abort
  call maktaba#ensure#IsString(a:request)
  call maktaba#ensure#IsString(a:name)
  call maktaba#ensure#IsDict(a:args)
  let l:new = {
      \ 'request': a:request,
      \ 'name': a:name,
      \ 'args': a:args,
      \ }
  return typevim#make#Class(s:typename, l:new)
endfunction
