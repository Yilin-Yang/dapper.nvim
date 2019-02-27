""
" @dict DebuggeeArgs
" Arguments for starting the debuggee process.

let s:typename = 'DebuggeeArgs'

""
" @public
" @dict DebuggeeArgs
" Construct a DebuggeeArgs object.
"
" {request} is either `"launch"` or `"attach"`.
"
" {name} is a "human-friendly" name for this debug adapter configuration.
"
" @throws WrongType if {request} or {name} aren't strings.
function! dapper#config#DebuggeeArgs#New(
    \ request,
    \ name) abort
  call maktaba#ensure#IsString(a:request)
  call maktaba#ensure#IsString(a:name)
  let l:new = {
      \ 'request': a:request,
      \ 'name': a:name,
      \ }
  return typevim#make#Class(s:typename, l:new)
endfunction
