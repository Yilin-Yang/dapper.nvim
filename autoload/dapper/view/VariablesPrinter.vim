""
" @dict VariablesPrinter
" An object for printing the contents of scopes and variables.
"
" Provides functions for printing, collapsing, and expanding scoped blocks of
" text: in this case, actual variable scopes and the variables therein. Meant
" manipulate in this case, actual variable scopes and the variables therein.
" Also provides functions for checking to see which items the user is trying
" to modify. Meant to be used as a member of a VariablesBuffer.
"
" Most member functions take in a `{lookup_path_of_var}` See
" @dict(VariableLookup) for information on how this argument should be
" structured.

let s:typename = 'VariablesPrinter'

""
" @public
" @dict VariablesPrinter
" @function dapper#view#VariablesPrinter#New({message_passer}, {var_lookup})
" Construct a VariablesPrinter.
"
" {message_passer} is an object satisfying the @dict(MiddleTalker) interface.
" {buffer} is the |TypeVim.Buffer| object that this object will manipulate.
" {vars_lookup} is a @dict(VariableLookup) object.
"
" @throws BadValue if {message_passer}, {buffer}, or {var_lookup} are not dicts.
" @throws WrongType if {message_passer} does not implement a @dict(MiddleTalker) interface, {buffer} is not a |TypeVim.Buffer|, or {var_lookup} does not implement a @dict(VariableLookup) interface.
function! dapper#view#VariablesPrinter#New(message_passer, buffer, var_lookup) abort
  call typevim#ensure#Implements(
      \ a:message_passer, dapper#MiddleTalker#Interface())
  call typevim#ensure#IsType(a:buffer, 'Buffer')
  call typevim#ensure#Implements(
      \ a:var_lookup, dapper#model#VariableLookup#Interface())

  let l:new = {
      \ '_message_passer': a:message_passer,
      \ '_buffer': a:buffer,
      \ '_var_lookup': a:var_lookup,
      \ 'PrintVariable': typevim#make#Member('PrintVariable'),
      \ 'GetRange': typevim#make#Member('GetRange'),
      \ 'VarFromCursor': typevim#make#Member('VarFromCursor'),
      \ 'ExpandEntry': typevim#make#Member('ExpandEntry'),
      \ 'CollapseEntry': typevim#make#Member('CollapseEntry'),
      \ }

  return typevim#make#Class(s:typename, l:new)
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" Given a line of text from a VariablesPrinter-managed buffer that contains a
" variable, parse that text into a dict and return it.
"
" If no match was made, return an empty dictionary.
function! dapper#view#VariablesPrinter#VariableFromString(string) abort
  call maktaba#ensure#IsString(a:string)
  let l:matches = matchlist(a:string, s:VARIABLE_PATTERN)
  if empty(l:matches) | return {} | endif
  return {
      \ 'indentation': l:matches[1],
      \ 'expanded': l:matches[2] ==# 'v',
      \ 'unstructured': l:matches[2] ==# '-',
      \ 'name': l:matches[3],
      \ 'type': l:matches[4],
      \ 'presentation_hint': l:matches[5],
      \ 'value': l:matches[6],
      \ }
endfunction

""
" Return a regex pattern that matches a variable with the given [indentation],
" [name], and [type]. All of these default to matching any text, if not
" provided.
function! s:VariablePattern(...) abort
  let l:indentation = maktaba#ensure#IsString(get(a:000, 0, '[ ]\{-}'))
  let l:name = maktaba#ensure#IsString(get(a:000, 1, '.\{-}'))
  let l:type = maktaba#ensure#IsString(get(a:000, 2, '.\{-}'))
  return '^\('.l:indentation.'\)\([>v-]\) \('.l:name.'\), \('.l:type.
      \ '\)\%(, \(.\{-}\)\)\{0,1}:\%( \(.*\)\)\?$'
endfunction

let s:VARIABLE_PATTERN = s:VariablePattern()
lockvar s:VARIABLE_PATTERN

""
" Given a line of text from a VariablesPrinter-managed buffer that contains a
" scope, parse that text into a dict and return it.
"
" If no match was made, return an empty dictionary.
function! dapper#view#VariablesPrinter#ScopeFromString(string) abort
  call maktaba#ensure#IsString(a:string)
  let l:matches = matchlist(a:string, s:SCOPE_PATTERN)
  if empty(l:matches) | return {} | endif
  return {
      \ 'expanded': l:matches[1] ==# 'v',
      \ 'name': l:matches[2],
      \ 'info': l:matches[3],
      \ }
endfunction

""
" Return a regex pattern that matches a scope with [name]. If [name] is not
" provided, match a scope with any name.
function! s:ScopePattern(...) abort
  let l:name = maktaba#ensure#IsString(get(a:000, 0, '.*'))
  return '^\([>v]\) \('.l:name.'\) :\%( \(.*\)\)\?$'
endfunction

let s:SCOPE_PATTERN = s:ScopePattern()
lockvar s:SCOPE_PATTERN

""
" @public
" Get the range of lines in the managed buffer in which the given variable is
" printed. Takes in a {lookup_path_of_var}.
"
" Returns a two-element list: the first and last line containing the requested
" variable, inclusive.
"
" @throws BadValue if {lookup_path_of_var} contains values that aren't strings, or is empty.
" @throws NotFound if no matching variable could be found. This may also occur if the requested variable is hidden in a collapsed block.
" @throws WrongType if {lookup_path_of_var} is not a list.
function! dapper#view#VariablesPrinter#GetRange(lookup_path_of_var) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsList(a:lookup_path_of_var)
  if empty(a:lookup_path_of_var)
    throw maktaba#error#BadValue('Gave empty lookup path in call to GetRange!')
  endif
  for l:Val in a:lookup_path_of_var
    if !maktaba#value#IsString(l:Val)
      throw maktaba#error#BadValue(
          \ 'Gave non-string component %s in lookup path: %s',
          \ typevim#PrintShallow(l:Val),
          \ typevim#PrintShallow(a:lookup_path_of_var))
    endif
  endfor
  let l:buffer = l:self._buffer

  " match scope
  let l:scope = a:lookup_path_of_var[0]
  unlet a:lookup_path_of_var[0]
  let l:scope_pattern = s:ScopePattern(l:scope)
  let l:scope_start = l:buffer.search(l:scope_pattern, 'wc')
  if !l:scope_start
    throw maktaba#error#NotFound('Could not find scope: '.l:scope)
  endif
  let l:scope_end = l:buffer.search(s:SCOPE_PATTERN, 'Wc', l:scope_start + 1)
  if !l:scope_end  " hit end of buffer during search
    let l:scope_end = l:buffer.NumLines()
  else
    let l:scope_end -= 1
  endif

  if empty(a:lookup_path_of_var)  " user only wanted a scope
    return [l:scope_start, l:scope_end]
  endif

  " from there, match variable, etc.
  return s:GetVariableRange(l:self._buffer, a:lookup_path_of_var)
endfunction

function! s:GetVariableRange(buffer, lookup_path_of_var, search_start,
                           \ search_end, ...) abort
  let l:cur_indent_level = get(a:000, 0, 1)
  let l:indent = typevim#value#GetIndentBlock(l:cur_indent_level)

  let l:var = a:lookup_path_of_var[0]
  unlet a:lookup_path_of_var[0]

  let l:var_pattern = s:VariablePattern(l:indent, l:var)
  let l:var_start = a:buffer.search(
      \ l:var_pattern, 'Wc', a:search_start, a:search_end)
  if !l:var_start
    throw maktaba#error#NotFound('Could not find variable: ' + l:var)
  endif
  let l:var_end = a:buffer.search(
      \ s:VARIABLE_PATTERN, 'Wc', l:var_start + 1, a:search_end)

  if empty(a:lookup_path_of_var)
    return [l:var_start, l:var_end]
  endif

  return s:GetVariableRange(a:buffer, a:lookup_path_of_var, l:var_start,
                          \ l:var_end, l:cur_indent_level + 1)
endfunction

""
" @public
" @dict VariablesPrinter
" Given a cursor position in the managed buffer (as returned by `getpos('.')`
" or by |getcurpos()|), return the variable or scope in which that cursor
" position lay.
"
" If [return_as_lookup_path] is 1, the requested scope or variable will be
" returned as a lookup path. If it's 0, this function will return a
" @dict(Scope) or @dict(Variable), as appropriate.
"
" @default return_as_lookup_path=0
" @throws BadValue if the given {curpos} does not include, at least, `bufnum`, `lnum`, `col`, and `off`. See |getpos()|, or if any of these are not numbers.
" @throws NotFound if the given {curpos} does not correspond to any scope or variable in the managed buffer.
" @throws WrongType if the given {curpos} is not a list, or if [return_as_lookup_path] is not a bool.
function! dapper#view#VariablesPrinter#VarFromCursor(curpos, ...) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsList(a:curpos)
  let l:return_as_lookup_path = typevim#ensure#IsBool(get(a:000, 0, 0))
  " TODO
endfunction

""
" @public
" @dict VariablesPrinter
" Expand the given scope or variable in the managed buffer. If the expansion
" was successful, return 1. If it was not (e.g. the variable was already
" expanded, or the variable is not a "structured" variable that can be
" expanded) return 0.
"
" If the given scope/variable lay within another collapsed scope/variable,
" this function will recursively expand all "parent" scopes/variables.
"
" @throws BadValue if {lookup_path_of_var} contains values that aren't strings.
" @throws NotFound if {lookup_path_of_var} corresponds to no known scope or variable.
" @throws WrongType if the given {lookup_path_of_var} is not a list.
function! dapper#view#VariablesPrinter#ExpandEntry() dict abort
  call s:CheckType(l:self)
  " TODO
endfunction

""
" @public
" @dict VariablesPrinter
" Expand the given scope or variable in the managed buffer. If the collapse
" was successful, return 1. If it was not (e.g. the variable was already
" collapsed, or the variable is not a "structured" variable that can be
" collapsed) return 0.
"
" Does not recursively collapse structured variables inside the requested
" scope/variable.
"
" @throws BadValue if {lookup_path_of_var} contains values that aren't strings.
" @throws NotFound if {lookup_path_of_var} corresponds to no known scope or variable.
" @throws WrongType if the given {lookup_path_of_var} is not a list.
function! dapper#view#VariablesPrinter#CollapseEntry() dict abort
  call s:CheckType(l:self)
  " TODO
endfunction
