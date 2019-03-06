""
" @dict Scope
" Stores the variables found in a particular DebugProtocol.Scope.

let s:typename = 'Scope'

""
" @public
" @function dapper#model#Scope#New({raw_scope}, {vars_response})
" @dict Scope
"
" Construct a new Scope object.
"
" @throws BadValue if {raw_scope} and {vars_response} aren't both dicts.
" @throws WrongType if {raw_scope} is not a DebugProtocol.Scope or {vars_response} is not a DebugProtocol.VariablesResponse.
function! dapper#model#Scope#New(raw_scope, vars_response) abort
  call typevim#ensure#Implements(a:raw_scope, dapper#dap#Scope())
  call typevim#ensure#Implements(a:vars_response, dapper#dap#VariablesResponse())

  " TODO
  let l:new = {
      \ 'raw_scope': a:raw_scope,
      \ 'vars_response': a:vars_response,
      \ }
  return typevim#make#Class(s:typename, l:new)
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction
