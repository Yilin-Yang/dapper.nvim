""
" @dict VariablesPrinter
" An object for printing the contents of scopes and variables.
"
" Provides functions for printing, collapsing, and expanding scoped blocks of
" text: in this case, actual variable scopes and the variables therein. Meant
" manipulate in this case, actual variable scopes and the variables therein.
" Also provides functions for checking to see which items the user is trying
" to modify.
"
" Meant to be a "single-use" member variable in a VariablesBuffer, in that it
" should be replaced with a new VariablesPrinter once the VariablesBuffer has
" been pushed a new StackFrame.
"
" Most member functions take in a `{lookup_path_of_var}` See
" @dict(VariableLookup) for information on how this argument should be
" structured.

let s:typename = 'VariablesPrinter'

let s:plugin = maktaba#plugin#Get('dapper.nvim')

""
" @public
" @dict VariablesPrinter
" @function dapper#view#VariablesPrinter#New({message_passer}, {buffer}, {var_lookup})
" Construct a VariablesPrinter.
"
" {message_passer} is an object satisfying the @dict(MiddleTalker) interface.
" {buffer} is the |TypeVim.Buffer| object that this object will manipulate.
" {var_lookup} is a @dict(VariableLookup) object.
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
      \ '_pending_prints': {},
      \ 'PrintVariable': typevim#make#Member('PrintVariable'),
      \ 'GetRange': typevim#make#Member('GetRange'),
      \ 'VarFromCursor': typevim#make#Member('VarFromCursor'),
      \ 'ExpandEntry': typevim#make#Member('ExpandEntry'),
      \ 'CollapseEntry': typevim#make#Member('CollapseEntry'),
      \ 'UpdateValue': typevim#make#Member('UpdateValue'),
      \ 'PrintScopes': typevim#make#Member('PrintScopes'),
      \ '_LogFailure': typevim#make#Member('_LogFailure'),
      \ '_PrintCollapsedChildren': typevim#make#Member('_PrintCollapsedChildren'),
      \ }

  let l:new._LogFailure =
      \ typevim#object#Bind(l:new._LogFailure, l:new)
  let l:new._PrintCollapsedChildren =
      \ typevim#object#Bind(l:new._PrintCollapsedChildren, l:new)

  return typevim#make#Class(s:typename, l:new)
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

function! s:EscapeMagicChars(string) abort
  return typevim#string#EscapeChars(a:string, '\[]$.*~')
endfunction

""
" Convert the given @dict(Variable) {variable} into the "compact struct" used
" by functions like @function(dapper#view#VariablesPrinter#StringFromVariable).
"
" {lookup_path} is the lookup path to {variable}.
"
" The returned struct defaults to being collapsed, if {variable} is
" structured. If [expanded] is true, and {variable} is structured, then it
" will be expanded.
"
" @default expanded=0
function! s:DictVariableToStruct(lookup_path, variable, ...) abort
  call maktaba#ensure#IsList(a:lookup_path)
  call typevim#ensure#IsType(a:variable, 'Variable')
  let l:expanded = typevim#ensure#IsBool(get(a:000, 0, 0))
  let l:to_return = {
      \ 'indentation': typevim#object#GetIndentBlock(len(a:lookup_path) - 1),
      \ 'expanded': 0,
      \ 'unstructured': !a:variable.HasChildren(),
      \ 'name': a:variable.name(),
      \ 'type': '',
      \ 'presentation_hint': '',
      \ 'value': a:variable.value(),
      \ }
  if !l:to_return.unstructured && l:expanded
    let l:to_return.expanded = 1
  endif

  let l:type = a:variable.type()
  if l:type isnot v:null
    let l:to_return.type = l:type
  endif

  let l:hint = a:variable.presentationHint()
  if l:hint isnot v:null
    let l:to_return.presentation_hint = l:hint
  endif

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
  let l:named = a:scope.namedVariables()
  if l:named isnot v:null
    let l:info = l:named.' named'
  endif

  let l:indexed = a:scope.indexedVariables()
  if l:indexed isnot v:null
    let l:to_add =
        \ (empty(l:info) ? '' : ', ') . l:indexed
        \ . ' indexed'
    let l:info .= l:to_add
  endif

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
  let l:name = a:0 ># 1 ? s:EscapeMagicChars(a:2) : '.\{-}'
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
  let l:name = a:0 ? s:EscapeMagicChars(a:1) : '.*'
  return '^\([>v]\) \('.l:name.'\) :\%( \(.*\)\)\?$'
endfunction

let s:SCOPE_PATTERN = s:ScopePattern()
lockvar s:SCOPE_PATTERN

""
" @dict VariablesPrinter
" Asynchronously (and recursively) print the given {children} into the
" managed buffer underneath the given parent {var_or_scope}. Also updates the
" {var_or_scope}'s trailing "info" (i.e. the text that reads "5 numbered, 6
" indexed", etc.), if possible.
"
" Assumes that the parent {var_or_scope} has already been printed in the
" managed buffer, i.e. a GetRange call to find the parent will not throw an
" ERROR(NotFound).
"
" {child_of} is the lookup path of {var_or_scope}. In practice, if {child_of}
" is nonempty, the variables in {children} must be @dict(Variable)s.
"
" {rec_depth} is the number of "levels deep" to which {var_or_scope} and its
" children should be printed. If equal to 1, only {var_or_scope} and {children}
" will be printed in a "collapsed" state. If equal to 2, {var_or_scope} will
" be printed, its {children} will be printed, and the children's children will
" be printed in a "collapsed" state, and so on.
"
" {children} is a dict between variable indices/names and corresponding
" @dict(Variable) objects.
"
" @throws BadValue if {var_or_scope} is not a dict, {child_of} contains non-string values, or {rec_depth} is not a positive number.
" @throws WrongType if {var_or_scope} is not a @dict(Variable) or a @dict(Scope), {child_of} is not a list, or {rec_depth} is not a number, or {children} is not a dict.
function! dapper#view#VariablesPrinter#_PrintCollapsedChildren(
    \ child_of, rec_depth, var_or_scope, children) dict abort
  call maktaba#ensure#IsNumber(a:rec_depth)
  if a:rec_depth <# 1
    throw maktaba#error#BadValue(
        \ 'rec_depth in PrintCollapsedChildren must be positive, gave: %d',
        \ a:rec_depth)
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

  try
    let [l:parent_start, l:parent_end] = l:self.GetRange(a:child_of)
  catch /ERROR(NotFound)/
    " var_or_scope has not yet been printed; set an async callback to proceed
    " with printing once it has been
    let l:args = [a:child_of, a:rec_depth, a:var_or_scope, a:children]
    let l:self._pending_prints[string(a:child_of)] =
        \ [a:child_of, a:rec_depth, a:var_or_scope]
    call l:self._message_passer.NotifyReport(
        \ 'info', 'Parent '.a:child_of[-1]." wasn't printed; sleeping.", l:args)
    return
  endtry
  if (l:parent_start != l:parent_end)
    " the parent was already expanded; clear all of its current children,
    " since we're going to overwrite them
    call l:self._buffer.DeleteLines(l:parent_start + 1, l:parent_end)
  endif

  " if there's a parent, change its prefix from '>' to 'v'
  if typevim#value#IsType(a:var_or_scope, 'Scope')
    let l:parent = s:DictScopeToStruct(a:var_or_scope, 1)
    let l:parent_str =
        \ dapper#view#VariablesPrinter#StringFromScope(l:parent, 0)
  else  " parent is Variable
    let l:parent =
        \ s:DictVariableToStruct(a:child_of, a:var_or_scope, 1)
    let l:parent_str =
        \ dapper#view#VariablesPrinter#StringFromVariable(l:parent, 'v')
  endif
  call l:self._buffer.ReplaceLines(
      \ l:parent_start, l:parent_start, [l:parent_str])

  " sort children in alphabetical order by name
  let l:name_and_var = sort(items(a:children),
                          \ function('typevim#value#CompareKeys'))

  let l:print_after = l:parent_end
  for [l:name, l:var] in l:name_and_var
    call maktaba#ensure#IsString(l:name)
    call typevim#ensure#IsType(l:var, 'Variable')

    " the path to this child variable
    let l:child_path = a:child_of + [l:name]

    let l:has_children = l:var.HasChildren()
    let l:var_struct = s:DictVariableToStruct(l:child_path, l:var)
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

    let l:child_path_as_str = string(l:child_path)
    call l:self._message_passer.NotifyReport(
        \ 'debug', 'Setting up child: '.l:child_path_as_str)

    " if any prints were waiting for one of these children to be printed,
    " fire them
    if has_key(l:self._pending_prints, l:child_path_as_str)
      let l:print_collapsed_args = l:self._pending_prints[l:child_path_as_str]
      call l:self._message_passer.NotifyReport(
          \ 'info', 'Firing pending print for: '.l:name, l:print_collapsed_args)
      unlet l:self._pending_prints[l:child_path_as_str]

      " note: PrintCollapsedChildren needs to be an atomic operation
      " (interruptions will throw off line numbers) so set a Promise that will
      " callback after this call returns
      call l:print_collapsed_args[2].Children().Then(
          \ function(l:self._PrintCollapsedChildren, l:print_collapsed_args),
          \ function(l:self._LogFailure, ['"fire pending print"']))
    endif

    let l:var_path = a:child_of + [l:var.name()]
    if a:rec_depth ># 1 && l:has_children
      call l:var.Children().Then(
          \ function(l:self._PrintCollapsedChildren,
            \ [l:var_path, a:rec_depth - 1, l:var]),
          \ function(l:self._LogFailure, ['"expand entry"']))
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
    let l:scope_end = l:buffer.NumLines() - 1
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

  " if it's the first line in the buffer, with the <variables> tag,
  " increment by one. if it's the very last line, with the </variables> tag,
  " decrement by one.
  if l:line_no ==# 1
    let l:line_no += 1
  elseif l:line_no ==# l:self._buffer.NumLines()
    let l:line_no -= 1
  endif
  let l:line = l:self._buffer.GetLines(l:line_no)[0]

  let l:var = dapper#view#VariablesPrinter#VariableFromString(l:line)
  if empty(l:var)  " is a scope
    let l:scope = dapper#view#VariablesPrinter#ScopeFromString(l:line)
    if empty(l:scope)  " actually, not even a scope; there's just nothing
      throw maktaba#error#NotFound(
          \ 'Given curpos does not correspond to any scope: %s',
          \ typevim#PrintShallow(a:curpos))
    endif
    return l:return_as_lookup_path ?
        \ [l:scope.name] : l:self._var_lookup.VariableFromPath([l:scope.name])
  endif
  " is a variable
  if empty(l:var)
    throw maktaba#error#NotFound(
        \ 'Given curpos does not correspond to any var: %s',
        \ typevim#PrintShallow(a:curpos))
  endif
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
" If the given {var_or_scope} is an unstructured variable, simply update that
" variable's value in the managed buffer. [rec_depth] will have no effect.
"
" [rec_depth] is the number of "levels deep" to which {var_or_scope} and its
" children should be printed. If equal to 1, only {var_or_scope} will be
" printed in a "collapsed" state. If equal to 2, {var_or_scope} will be
" printed, and its immediate children will be printed in a "collapsed" state,
" and so on.
"
" @default rec_depth=3
" @throws BadValue if {lookup_path_of_var} contains values that aren't strings, or if [rec_depth] is not a positive number.
" @throws NotFound if {lookup_path_of_var} corresponds to no known scope or variable.
" @throws WrongType if the given {lookup_path_of_var} is not a list.
function! dapper#view#VariablesPrinter#ExpandEntry(
    \ lookup_path, var_or_scope, ...) dict abort
  call s:CheckType(l:self)
  let l:rec_depth = maktaba#ensure#IsNumber(get(a:000, 0, 3))
  if l:rec_depth <# 1
    throw maktaba#error#BadValue(
        \ 'rec_depth in ExpandEntry must be positive, gave: %d', l:rec_depth)
  endif
  let [l:start, l:end] = l:self.GetRange(a:lookup_path)
  let l:start_line = l:self._buffer.GetLines(l:start)[0]

  if len(a:lookup_path) ==# 1  " is Scope
    let l:scope = dapper#view#VariablesPrinter#ScopeFromString(l:start_line)
    if l:scope.expanded | return 0 | endif
    let l:expanded_str =
        \ dapper#view#VariablesPrinter#StringFromScope(l:scope, 1)
    call a:var_or_scope.variables().Then(
        \ function(l:self._PrintCollapsedChildren,
          \ [a:lookup_path, l:rec_depth, a:var_or_scope]),
        \ function(l:self._LogFailure, ['"expand Scope"']))
  else  " is Variable
    let l:var = dapper#view#VariablesPrinter#VariableFromString(l:start_line)
    if l:var.unstructured
      call l:self.UpdateValue(a:lookup_path, a:var_or_scope)
      return 0
    endif
    if l:var.expanded | return 0 | endif
    let l:expanded_str =
        \ dapper#view#VariablesPrinter#StringFromVariable(l:var, 'v')
    call a:var_or_scope.Children().Then(
        \ function(l:self._PrintCollapsedChildren,
          \ [a:lookup_path, l:rec_depth, a:var_or_scope]),
        \ function(l:self._LogFailure, ['"expand Variable"']))
  endif
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

""
" @public
" @dict VariablesPrinter
" Update the value of a @dict(Variable) in the managed buffer.
"
" {new_props} is a dictionary that may contain:
" - value: A string, the new value of the variable.
" - type?: An optional string, the variable's new type.
" - namedVariables?: An optional number, the number of named child variables.
" - indexedVariables?: An optional number, the number of indexed child
"   variables.
"
" {new_props} may also be a @dict(Variable), in which case it will be
" converted into a dictionary matching the structure above.
"
" Properties with keys not matching the above are silently ignored. If
" {lookup_path} corresponds to a @dict(Scope), the `value` key has no effect.
" Unspecified properties are not modified.
"
" @throws BadValue if {lookup_path} contains values that aren't strings, or if {lookup_path} is empty, or if {new_props} is not a dict.
" @throws NotFound if {lookup_path} corresponds to no known scope or variable.
" @throws WrongType if the given {lookup_path} is not a list, or if {new_props} does not conform to the interface described above.
function! dapper#view#VariablesPrinter#UpdateValue(
    \ lookup_path, new_props) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsList(a:lookup_path)
  if !typevim#value#Implements(a:new_props, s:new_props_interface)
    let l:given_var = typevim#ensure#IsType(a:new_props, 'Variable')
    let l:new_props = {}
    for l:prop in ['value', 'type', 'namedVariables', 'indexedVariables']
      let l:new_props[l:prop] = l:given_var[l:prop]()
      if l:new_props[l:prop] is v:null
        unlet l:new_props[l:prop]
      endif
    endfor
    call typevim#ensure#Implements(l:new_props, s:new_props_interface)
  else
    let l:new_props = a:new_props
  endif
  if empty(a:lookup_path)
    throw maktaba#error#BadValue('Gave empty lookup path in call to UpdateValue!')
  else
    let l:is_scope = len(a:lookup_path) ==# 1
  endif
  let [l:start, l:end] = l:self.GetRange(a:lookup_path)
  let l:header = l:self._buffer.GetLines(l:start)[0]
  if l:is_scope
    let l:parsed_scope = dapper#view#VariablesPrinter#ScopeFromString(l:header)
    let l:info = ''
    if has_key(l:new_props, 'namedVariables')
      let l:info .= l:new_props.namedVariables.' named'
    endif
    if has_key(l:new_props, 'indexedVariables')
      let l:info .= (empty(l:info) ? '' : ', ')
                  \ . l:new_props.indexedVariables . 'indexed'
    endif
    if !empty(l:info) | let l:parsed_scope.info = l:info | endif
    let l:header = dapper#view#VariablesPrinter#StringFromScope(
        \ l:parsed_scope, l:parsed_scope.expanded)
  else  " is variable
    let l:parsed_var = dapper#view#VariablesPrinter#VariableFromString(l:header)
    let l:parsed_var.value = l:new_props.value
    let l:prefix = '-'
    if !l:parsed_var.unstructured
      let l:prefix = l:parsed_var.expanded ? 'v' : '>'
    endif
    let l:header = dapper#view#VariablesPrinter#StringFromVariable(
        \ l:parsed_var, l:prefix)
  endif
  call l:self._buffer.ReplaceLines(l:start, l:start, [l:header])
endfunction
let s:new_props_interface = {
    \ 'value': typevim#String(),
    \ 'type?': typevim#String(),
    \ 'namedVariables?': typevim#Number(),
    \ 'indexedVariables?': typevim#Number(),
    \ }
call typevim#make#Interface('NewPropsInterface', s:new_props_interface)

""
" @public
" @dict VariablesBuffer
" Print each scope in {scopes} as a collapsed item at the top of the
" managed buffer, after the leading `<variables>` tag, making asynchronous
" requests to expand each one.
"
" {scopes} is a list of strings, with each string being the name of a
" @dict(Scope) in the stack frame being shown.
"
" @default rec_depth=3
" @throws WrongType if {scopes} is a not list of strings, or [rec_depth] is not a number.
function! dapper#view#VariablesPrinter#PrintScopes(scopes, ...) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsList(a:scopes)
  let l:rec_depth = maktaba#ensure#IsNumber(get(a:000, 0, 3))
  let l:var_lookup = l:self._var_lookup
  let l:names_to_scopes = {}
  for l:scope in a:scopes
    let l:names_to_scopes[maktaba#ensure#IsString(l:scope)] =
        \ l:var_lookup.VariableFromPath([l:scope])
  endfor

  let l:scopes_order = s:plugin.Flag('preferred_scope_order')
  let l:ordered_names_and_scopes = []
  for l:name in l:scopes_order
    if !has_key(l:names_to_scopes, l:name) | continue | endif

    call add(l:ordered_names_and_scopes,
           \ [l:name, l:names_to_scopes[l:name]])
    unlet l:names_to_scopes[l:name]
  endfor
  " any scopes remaining in the dict were not mentioned in the preferred order
  for l:unmentioned in
      \ sort(items(l:names_to_scopes), function('typevim#value#CompareKeys'))
    call add(l:ordered_names_and_scopes, l:unmentioned)
  endfor

  let l:print_after = 1
  let l:buffer = l:self._buffer
  for [l:name, l:scope_promise] in l:ordered_names_and_scopes
    let l:scope_header =
        \ dapper#view#VariablesPrinter#StringFromScope(
            \ {'expanded': 0, 'name': l:name, 'info': ''}, 1)
    call l:buffer.InsertLines(l:print_after, [l:scope_header])
    let l:print_after += 1

    if l:rec_depth ># 0
      call l:scope_promise.Then(
          \ function('s:ExpandScope', [l:self, [l:name], l:rec_depth]),
          \ function(l:self._LogFailure, ['"expand all Scopes"']))
    endif
  endfor
endfunction

function! s:ExpandScope(printer, lookup_path, rec_depth, scope) abort
  call a:printer.ExpandEntry(
      \ a:lookup_path, a:scope, a:rec_depth)
endfunction

""
" @public
" @dict VariablesPrinter
" Show/Log information about a failed asynchronous buffer update.
"
" {update_type} is the type of the failed update (e.g. asynchronous entry
" expansion, update variable value, etc.). [more] is any other relevant
" information, e.g. a |v:exception|, and can be of any type.
"
" @default more=""
" @throws WrongType if {update_type} is not a string.
function! dapper#view#VariablesPrinter#_LogFailure(update_type, ...) dict abort
  call maktaba#ensure#IsString(a:update_type)
  let l:more = get(a:000, 0, '')
  call l:self._message_passer.NotifyReport(
      \ 'warn', printf('VariablesBuffer %s update failed!', a:update_type),
      \ l:more)
endfunction
