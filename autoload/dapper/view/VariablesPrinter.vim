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
      \ '_PrintCollapsedChildren': typevim#make#Member('_PrintCollapsedChildren'),
      \ '_PrintExpandedChild': typevim#make#Member('_PrintExpandedChild'),
      \ }

  let l:new._PrintCollapsedChildren =
      \ typevim#object#Bind(l:new._PrintCollapsedChildren, l:new)
  let l:new._PrintExpandedChild =
      \ typevim#object#Bind(l:new._PrintExpandedChild, l:new)

  return typevim#make#Class(s:typename, l:new)
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" Convert the given @dict(Variable) {variable} into the "compact struct" used
" by functions like @function(dapper#view#VariablesPrinter#StringFromVariable).
"
" {child_of} is the lookup path to the parent of {variable}.
"
" The returned struct defaults to being collapsed, if {variable} is
" structured. If [expanded] is true, and {variable} is structured, then it
" will be expanded.
"
" @default expanded=0
function! s:DictVariableToStruct(child_of, variable, ...) abort
  call maktaba#ensure#IsList(a:child_of)
  call typevim#ensure#IsType(a:variable, 'Variable')
  let l:expanded = typevim#ensure#IsBool(get(a:000, 0, 0))
  let l:to_return = {
      \ 'indentation': typevim#object#GetIndentBlock(len(a:child_of)),
      \ 'expanded': 0,
      \ 'unstructured': a:variable.HasChildren(),
      \ 'name': a:variable.name(),
      \ 'type': '',
      \ 'presentation_hint': '',
      \ 'value': a:variable.value(),
      \ }
  if !l:to_return.unstructured && l:expanded
    let l:to_return.expanded = 1
  endif
  try | let l:to_return.type = a:variable.type()
  catch /ERROR(NotFound)/
  endtry

  try | let l:to_return.presentation_hint = a:variable.presentationHint()
  catch /ERROR(NotFound)/
  endtry

  return l:to_return
endfunction

""
" Convert the given @dict(Scope) into the "compact struct" used by functions
" like @function(dapper#view#VariablesPrinter#StringFromScope).
"
" The returned struct defaults to being collapsed, if {variable} is
" structured. If [expanded] is true, and {variable} is structured, then it
" will be expanded.
"
" @default expanded=0
function! s:DictScopeToStruct(scope, ...) abort
  call typevim#ensure#IsType(a:scope, 'Scope')
  " TODO figure out a more modular way of printing scope info?
  let l:to_return = {
      \ 'expanded': typevim#ensure#IsBool(get(a:000, 0, 0)) ==# 1,
      \ 'name': a:scope.name(),
      \ 'info': '',
      \ }
  let l:info = ''
  try | let l:info = a:scope.namedVariables().' named'
  catch /ERROR(NotFound)/
  endtry
  try
    let l:to_add =
        \ (empty(l:info) ? '' : ', ') . a:scope.indexedVariables()
        \ . ' indexed'
    let l:info .= l:to_add
  catch /ERROR(NotFound)/
  endtry
  let l:to_return.info = l:info
  return l:to_return
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
" Convert the given variable into a string, suitable for printing into the
" managed buffer. The inverse of
" @function(dapper#view#VariablesPrinter#VariableFromString).
function! dapper#view#VariablesPrinter#StringFromVariable(variable, prefix) abort
  if !maktaba#value#IsIn(a:prefix, ['>', 'v', '-'])
    throw maktaba#error#Failure(
        \ 'Bad prefix "%s" when printing variable: %s', a:prefix,
        \ typevim#PrintShallow(a:variable))
  endif
  if !typevim#value#Implements(a:variable, s:variable_interface)
    throw maktaba#error#Failure(
        \ 'Failed to print malformed variable: %s',
        \ typevim#PrintShallow(a:variable))
  endif
  if a:prefix ==# '-' && !a:variable.unstructured
    throw maktaba#error#Failure(
        \ 'Tried to print structured variable as unstructured: %s',
        \ typevim#PrintShallow(a:variable))
  elseif a:prefix !=# '-' && a:variable.unstructured
    throw maktaba#error#Failure(
        \ 'Tried to print unstructured variable as structured: %s',
        \ typevim#PrintShallow(a:variable))
  endif
  let l:str = a:variable.indentation.a:prefix.' '.a:variable.name.', '
      \ .a:variable.type
  if !empty(a:variable.presentation_hint)
    let l:str .= ', '.a:variable.presentation_hint
  endif
  let l:str .= ':'
  if !empty(a:variable.value)
    let l:str .= ' '.a:variable.value
  endif
  return l:str
endfunction

let s:variable_interface = {
    \ 'indentation': typevim#String(),
    \ 'expanded': typevim#Bool(),
    \ 'unstructured': typevim#Bool(),
    \ 'name': typevim#String(),
    \ 'type': typevim#String(),
    \ 'presentation_hint': typevim#String(),
    \ 'value': typevim#String(),
    \ }
call typevim#make#Interface('ParsedVariable', s:variable_interface)


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
" Convert the given scope into a string, suitable for printing into the
" managed buffer. The inverse of
" @function(dapper#view#VariablesPrinter#ScopeFromString).
function! dapper#view#VariablesPrinter#StringFromScope(scope, collapsed) abort
  call typevim#ensure#IsBool(a:collapsed)
  if !typevim#value#Implements(a:scope, s:scope_interface)
    throw maktaba#error#Failure(
        \ 'Failed to print malformed scope: %s', typevim#PrintShallow(a:scope))
  endif
  let l:prefix = a:collapsed ? '>' : 'v'
  return l:prefix.' '.a:scope.name.' : '.a:scope.info
endfunction

let s:scope_interface = {
    \ 'expanded': typevim#Bool(),
    \ 'name': typevim#String(),
    \ 'info': typevim#String(),
    \ }
call typevim#make#Interface('ParsedScope', s:scope_interface)

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
" @dict VariablesPrinter
" Asynchronously (and recursively) print the given {var_or_scope} into the
" managed buffer underneath the given parent.
"
" Assumes that the parent scope or variable has already been printed in the
" managed buffer, i.e. a GetRange call to find the parent will not throw an
" ERROR(NotFound).
"
" {child_of} is the lookup path of the parent of {var_or_scope}. In practice,
" if {child_of} is nonempty, {var_or_scope} must be a @dict(Variable).
"
" {rec_depth} is the number of "levels deep" to which {var_or_scope} and its
" children should be printed. If equal to 1, only {var_or_scope} will be
" printed in a "collapsed" state. If equal to 2, {var_or_scope} will be
" printed, and its immediate children will be printed in a "collapsed" state,
" and so on.
"
" {children} is a dict between variable indices/names and corresponding
" @dict(Variable) objects.
"
" @default rec_depth=3
" @throws BadValue if {var_or_scope} is not a dict, {child_of} contains non-string values, or [rec_depth] is not a positive number.
" @throws WrongType if {var_or_scope} is not a @dict(Variable) or a @dict(Scope), {child_of} is not a list, or {rec_depth} is not a number, or {children} is not a dict.
function! dapper#view#VariablesPrinter#_PrintCollapsedChildren(
    \ child_of, rec_depth, var_or_scope, children) dict abort
  let l:rec_depth = maktaba#ensure#IsNumber(get(a:000, 0, 3))
  if l:rec_depth <# 1
    throw maktaba#error#BadValue(
        \ 'rec_depth in PrintVariable must be positive, gave: %d', l:rec_depth)
  endif
  if !maktaba#value#IsDict(a:var_or_scope)
    throw maktaba#error#BadValue('Given var_or_scope is not a dict: %s',
                               \ typevim#PrintShallow(a:var_or_scope))
  endif
  let l:is_var = typevim#value#IsType(a:var_or_scope, 'Variable')
  let l:is_sco = typevim#value#IsType(a:var_or_scope, 'Scope')
  if !(l:is_var || l:is_sco)
    throw maktaba#error#WrongType(
        \ 'Given var_or_scope is not a Variable or Scope: %s',
        \ typevim#PrintShallow(a:var_or_scope))
  endif
  call maktaba#ensure#IsDict(a:children)

  let [l:parent_start, l:parent_end] = l:self.GetRange(a:child_of)
  if (l:parent_start != l:parent_end)
    " the parent was already expanded; clear all of its current children,
    " since we're going to overwrite them
    call l:self._buffer.DeleteLines(l:parent_start + 1, l:parent_end)
  endif

  " if there's a parent, change its prefix from '>' to 'v'
  if l:is_var  " will only have a parent if this is a variable
    " try to parse parent as a Variable; if that fails, parse it as a Scope
    let l:parent_line = l:self._buffer.GetLines(l:parent_start)[0]
    let l:parent =
        \ dapper#view#VariablesPrinter#VariableFromString(l:parent_line)
    if empty(l:parent)
      let l:parent =
          \ dapper#view#VariablesPrinter#ScopeFromString(l:parent_line)
      let l:parent_str =
          \ dapper#view#VariablesPrinter#StringFromScope(l:parent, 0)
    else
      let l:parent_str =
          \ dapper#view#VariablesPrinter#StringFromVariable(a:child_of, 'v')
    endif
    call l:self._buffer.ReplaceLines(
        \ l:parent_start, l:parent_start, [l:parent_str])
  endif

  " sort children in alphabetical order by name
  let l:name_and_var = sort(items(a:children),
                          \ function('typevim#value#CompareKeys'))

  let l:print_after = l:parent_end
  for [l:name, l:var] in l:name_and_var
    call maktaba#ensure#IsString(l:name)
    call typevim#ensure#IsType(l:var, 'Variable')
    let l:has_children = l:var.HasChildren()
    let l:var_struct = s:DictVariableToStruct(l:var)
    if l:has_children
      let l:var_str =
          \ dapper#view#VariablesPrinter#StringFromVariable(l:var_struct, '>')
    else
      let l:var_str =
          \ dapper#view#VariablesPrinter#StringFromVariable(l:var_struct, '-')
    endif

    " print the first line of each child variable so that the callback
    " will be able to find an entry to update
    call l:self._buffer.InsertLines(l:print_after, [l:var_str])

    let l:var_path = [a:child_of] + [l:var.name()]
    if a:rec_depth ># 1 && l:has_children
      call l:var.Children().Then(
          \ function(l:self._PrintCollapsedChildren,
            \ [l:var_path, a:rec_depth - 1, l:var]))
    endif
    let l:print_after += 1
  endfor
endfunction


""
" @public
" @dict VariablesPrinter
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
  let l:lookup_path_of_var = copy(a:lookup_path_of_var)
  let l:buffer = l:self._buffer

  " match scope
  let l:scope = l:lookup_path_of_var[0]
  unlet l:lookup_path_of_var[0]
  let l:scope_pattern = s:ScopePattern(l:scope)
  let l:scope_start = l:buffer.search(l:scope_pattern, 'wc')
  if !l:scope_start
    throw maktaba#error#NotFound('Could not find scope: '.l:scope)
  endif
  let l:scope_end = l:buffer.search(s:SCOPE_PATTERN, 'W', l:scope_start)
  if !l:scope_end  " hit end of buffer during search
    let l:scope_end = l:buffer.NumLines()
  else
    let l:scope_end -= 1
  endif

  if empty(l:lookup_path_of_var)  " user only wanted a scope
    return [l:scope_start, l:scope_end]
  endif

  " from there, match variable, etc.
  return s:GetVariableRange(
      \ l:self._buffer, l:lookup_path_of_var, l:scope_start, l:scope_end)
endfunction

function! s:GetVariableRange(buffer, lookup_path_of_var, search_start,
                           \ search_end, ...) abort
  let l:cur_indent_level = get(a:000, 0, 1)
  let l:indent = typevim#object#GetIndentBlock(l:cur_indent_level)

  let l:var = a:lookup_path_of_var[0]
  unlet a:lookup_path_of_var[0]

  let l:var_pattern = s:VariablePattern(l:indent, l:var)
  let l:var_start = a:buffer.search(
      \ l:var_pattern, 'Wc', a:search_start, a:search_end)
  if !l:var_start
    throw maktaba#error#NotFound('Could not find variable: ' . l:var)
  endif

  " search till the next line with equal or lesser indentation, or the
  " end of the buffer, whichever comes first
  let l:terminate_pat = '^[ ]\{0,'.(l:cur_indent_level * 2).'}\S'
  let l:var_end = a:buffer.search(l:terminate_pat, 'W', l:var_start)

  if !l:var_end
    let l:var_end = a:buffer.NumLines()
  else
    let l:var_end -= 1
  endif

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
" @throws BadValue if the given {curpos} is not a four- or five-element list whose second element is a number.
" @throws NotFound if the given {curpos} does not correspond to any scope or variable in the managed buffer.
" @throws WrongType if the given {curpos} is not a list, or if [return_as_lookup_path] is not a bool.
function! dapper#view#VariablesPrinter#VarFromCursor(curpos, ...) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsList(a:curpos)
  if !maktaba#value#IsIn(len(a:curpos), [4, 5])
    throw maktaba#error#BadValue(
        \ 'Did not give a curpos as returned by getpos() or getcurpos(): %s',
        \ typevim#PrintShallow(a:curpos))
  endif
  let l:line_no = maktaba#ensure#IsNumber(a:curpos[1])
  let l:return_as_lookup_path = typevim#ensure#IsBool(get(a:000, 0, 0))

  let l:line = l:self._buffer.GetLines(l:line_no)[0]

  let l:var = dapper#view#VariablesPrinter#VariableFromString(l:line)
  if empty(l:var)  " is a scope
    let l:scope = dapper#view#VariablesPrinter#ScopeFromString(l:line)
    return l:return_as_lookup_path ?
        \ [l:scope.name] : l:self._var_lookup.VariableFromPath([l:scope.name])
  endif
  " is a variable
  let l:lookup_path = s:BacktrackLookupPath(
      \ l:self._buffer, [l:var.name], l:line_no, len(l:var.indentation) / 2)
  return l:return_as_lookup_path ?
      \ l:lookup_path : l:self._var_lookup.VariableFromPath(l:lookup_path)
endfunction

""
" Reconstruct a lookup path by backtracking from line number {search_start}.
"
" When first called, {working_lookup_path} contains the name of the
" VarFromCursor, and {cur_indent_level} is the indent level of that variable.
function! s:BacktrackLookupPath(buffer, working_lookup_path, search_start,
                              \ cur_indent_level) abort
  if a:cur_indent_level <=# 1
    " we've gotten the 'last' variable, next up is the scope
    let l:scope_line = a:buffer.search(s:SCOPE_PATTERN, 'bW', a:search_start)
    let l:scope = dapper#view#VariablesPrinter#ScopeFromString(
        \ a:buffer.GetLines(l:scope_line)[0])
    return [l:scope.name] + a:working_lookup_path
  endif

  let l:indent = typevim#object#GetIndentBlock(a:cur_indent_level - 1)

  let l:next_up_pattern = s:VariablePattern(l:indent)
  let l:next_up = a:buffer.search(l:next_up_pattern, 'bW', a:search_start)
  let l:variable = dapper#view#VariablesPrinter#VariableFromString(
      \ a:buffer.GetLines(l:next_up)[0])
  let l:updated_lookup_path = [l:variable.name] + a:working_lookup_path

  return s:BacktrackLookupPath(a:buffer, l:updated_lookup_path, l:next_up,
                             \ a:cur_indent_level - 1)
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
function! dapper#view#VariablesPrinter#ExpandEntry(lookup_path) dict abort
  call s:CheckType(l:self)
  let [l:start, l:end] = l:self.GetRange(a:lookup_path)
  let l:start_line = l:self._buffer.GetLines(l:start)[0]

  if len(a:lookup_path ==# 1)  " is Scope
    let l:scope = dapper#view#VariablesPrinter#ScopeFromString(l:start_line)
    if l:scope.expanded | return 0 | endif
    let l:expanded_str =
        \ dapper#view#VariablesPrinter#StringFromScope(l:scope, 1)
    " TODO and expand the children
  else  " is Variable
    let l:var = dapper#view#VariablesPrinter#VariableFromString(l:start_line)
    if l:var.expanded || l:var.unstructured | return 0 | endif
    let l:expanded_str =
        \ dapper#view#VariablesPrinter#StringFromVariable(l:var, 'v')
    " TODO and expland the children
  endif
  " TODO
  call l:self._buffer.ReplaceLines(l:start, l:end, [l:expanded_str])
  return 1
endfunction

""
" @public
" @dict VariablesPrinter
" Collapse the given scope or variable in the managed buffer. If the collapse
" was successful, return 1. If it was not (e.g. the variable was already
" collapsed, or the variable is not a "structured" variable that can be
" collapsed) return 0.
"
" @throws BadValue if {lookup_path_of_var} contains values that aren't strings.
" @throws NotFound if {lookup_path_of_var} corresponds to no known scope or variable.
" @throws WrongType if the given {lookup_path_of_var} is not a list.
function! dapper#view#VariablesPrinter#CollapseEntry(lookup_path) dict abort
  call s:CheckType(l:self)
  let [l:start, l:end] = l:self.GetRange(a:lookup_path)
  let l:start_line = l:self._buffer.GetLines(l:start)[0]

  if len(a:lookup_path) ==# 1  " is Scope
    let l:scope = dapper#view#VariablesPrinter#ScopeFromString(l:start_line)
    if !l:scope.expanded | return 0 | endif
    let l:collapsed_str =
        \ dapper#view#VariablesPrinter#StringFromScope(l:scope, 1)
  else  " is Variable
    let l:var = dapper#view#VariablesPrinter#VariableFromString(l:start_line)
    if !l:var.expanded || l:var.unstructured | return 0 | endif
    let l:collapsed_str =
        \ dapper#view#VariablesPrinter#StringFromVariable(l:var, '>')
  endif
  call l:self._buffer.ReplaceLines(l:start, l:end, [l:collapsed_str])
  return 1
endfunction
