""
" @dict Scope
" Stores the variables found in a particular DebugProtocol.Scope.

let s:typename = 'Scope'

""
" @public
" @function dapper#model#Scope#New({message_passer}, {raw_scope}, {vars_response})
" @dict Scope
"
" Construct a new Scope object.
"
" @throws BadValue if {message_passer}, {raw_scope}, and {vars_response} aren't all dicts.
" @throws WrongType if {message_passer} does not implement a @dict(MiddleTalker) interface, or if {raw_scope} is not a DebugProtocol.Scope or {vars_response} is not a DebugProtocol.VariablesResponse.
function! dapper#model#Scope#New(message_passer, raw_scope, vars_response) abort
  call typevim#ensure#Implements(a:message_passer, dapper#MiddleTalker#Interface())
  call typevim#ensure#Implements(a:raw_scope, dapper#dap#Scope())
  call typevim#ensure#Implements(a:vars_response, dapper#dap#VariablesResponse())

  if !a:vars_response.success
    call a:message_passer.NotifyReport(
        \ 'error',
        \ 'Scope constructor given failed VariablesResponse!',
        \ a:vars_response,
        \ a:raw_scope
        \ )
    throw maktaba#error#BadValue(
        \ 'Got bad VariablesResponse in model#Scope constructor: %s',
        \ typevim#object#ShallowPrint(a:vars_response))
  endif

  let l:new = {
      \ '_message_passer': a:message_passer,
      \ '_raw_scope': a:raw_scope,
      \ '_vars_response': a:vars_response,
      \ '_names_to_variables':
          \ s:ParseResponseIntoVariables(a:message_passer, a:vars_response),
      \
      \ 'name': typevim#make#Member('name'),
      \ 'variablesReference': typevim#make#Member('variablesReference'),
      \ 'namedVariables': typevim#make#Member('namedVariables'),
      \ 'indexedVariables': typevim#make#Member('indexedVariables'),
      \ 'expensive': typevim#make#Member('expensive'),
      \ 'source': typevim#make#Member('source'),
      \ 'line': typevim#make#Member('line'),
      \ 'column': typevim#make#Member('column'),
      \ 'endLine': typevim#make#Member('endLine'),
      \ 'endColumn': typevim#make#Member('endColumn'),
      \
      \ 'variables': typevim#make#Member('variables'),
      \ }
  return typevim#make#Class(s:typename, l:new)
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" Return {property} of {self}, if present. Else, return |v:null|.
function! s:ReturnPropIfPresent(self, property) abort
  call s:CheckType(a:self)
  call maktaba#ensure#IsString(a:property)
  if has_key(a:self._raw_scope, a:property)
    return a:self._raw_scope[a:property]
  endif
  return v:null
endfunction

""
" Parse the contents of the given {vars_response} into a dict between variable
" names/indices and the variables themselves.
function! s:ParseResponseIntoVariables(message_passer, vars_response) abort
  call typevim#ensure#Implements(a:message_passer, dapper#MiddleTalker#Interface())
  call typevim#ensure#Implements(a:vars_response, dapper#dap#VariablesResponse())
  let l:names_to_vars = {}
  for l:raw_var in a:vars_response.body.variables
    let l:names_to_vars[l:raw_var.name] =
        \ dapper#model#Variable#New(a:message_passer, l:raw_var)
  endfor
  return l:names_to_vars
endfunction

""
" @public
" @dict Scope
" Return the name of this Scope object, or |v:null| if it could not be found.
function! dapper#model#Scope#name() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'name')
endfunction

""
" @public
" @dict Scope
" Return the variablesReference property of this Scope object.
function! dapper#model#Scope#variablesReference() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'variablesReference')
endfunction

""
" @public
" @dict Scope
" Return the namedVariables property of this Scope object, or |v:null| if it
" could not be found..
function! dapper#model#Scope#namedVariables() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'namedVariables')
endfunction

""
" @public
" @dict Scope
" Return the indexedVariables property of this Scope object, or |v:null| if it
" could not be found.
function! dapper#model#Scope#indexedVariables() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'indexedVariables')
endfunction

""
" @public
" @dict Scope
" Return the expensive property of this Scope object, or |v:null| if it could
" not be found.
function! dapper#model#Scope#expensive() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'expensive')
endfunction

""
" @public
" @dict Scope
" Return the source property of this Scope object, or |v:null| if it could not
" be found.
function! dapper#model#Scope#source() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'source')
endfunction

""
" @public
" @dict Scope
" Return the line property of this Scope object, or |v:null| if it could not
" be found.
function! dapper#model#Scope#line() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'line')
endfunction

""
" @public
" @dict Scope
" Return the column property of this Scope object, or |v:null| if it could not
" be found.
function! dapper#model#Scope#column() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'column')
endfunction

""
" @public
" @dict Scope
" Return the endLine property of this Scope object, or |v:null| if it could
" not be found.
function! dapper#model#Scope#endLine() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'endLine')
endfunction

""
" @public
" @dict Scope
" Return the endColumn property of this Scope object, or |v:null| if it could
" not be found.
function! dapper#model#Scope#endColumn() dict abort
  call s:CheckType(l:self)
  return s:ReturnPropIfPresent(l:self, 'endColumn')
endfunction

""
" @public
" @dict Scope
" Return a |TypeVim.Promise| that resolves to a dict between this scope's
" variable names/indices and their corresponding @dict(Variable) objects.
function! dapper#model#Scope#variables() dict abort
  call s:CheckType(l:self)
  " probably not necessary, but just for interface consistency
  let l:to_return = typevim#Promise#New()
  call l:to_return.Resolve(copy(l:self._names_to_variables))
  return l:to_return
endfunction
