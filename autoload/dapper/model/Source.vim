""
" @dict Source
" Debuggee source code.

let s:typename = 'Source'

""
" @public
" @function dapper#model#Source#New({message_passer}, {source_obj}, [source_bps])
" @dict Source
" Construct a new Source object.
"
" @throws BadValue if {message_passer} or {source_obj} are not dicts.
" @throws WrongType if {message_passer} does not implement a @dict(MiddleTalker) interface, or if {source_obj} is not a DebugProtocol.Source.
function! dapper#model#Source#New(message_passer, source_obj) abort
  call typevim#ensure#Implements(
      \ a:message_passer, dapper#MiddleTalker#Interface())
  call typevim#ensure#Implements(a:source_obj, dapper#dap#Source())
  let l:new = {
      \ '_message_passer': a:message_passer,
      \ '_raw_source': a:source_obj,
      \ '_content': v:null,
      \ '_mime_type': v:null,
      \ '_bps': [],
      \
      \ 'name': typevim#make#Member('name'),
      \ 'path': typevim#make#Member('path'),
      \ 'sourceReference': typevim#make#Member('sourceReference'),
      \ 'presentationHint': typevim#make#Member('presentationHint'),
      \ 'origin': typevim#make#Member('origin'),
      \ 'sources': typevim#make#Member('sources'),
      \ 'adapterData': typevim#make#Member('adapterData'),
      \ 'checksums': typevim#make#Member('checksums'),
      \
      \ 'AbsolutePath': typevim#make#Member('AbsolutePath'),
      \ 'Contents': typevim#make#Member('Contents'),
      \ 'SetBreakpoint': typevim#make#Member('SetBreakpoint'),
      \ 'RemoveBreakpoint': typevim#make#Member('RemoveBreakpoint'),
      \
      \ '_UpdateContents': typevim#make#Member('_UpdateContents'),
      \ '_UpdateBreakpoints': typevim#make#Member('_UpdateBreakpoints'),
      \ }
  call typevim#make#Class(s:typename, l:new)
  let l:new._UpdateContents =
      \ typevim#object#Bind(l:new._UpdateContents, l:new)
  let l:new._UpdateBreakpoints =
      \ typevim#object#Bind(l:new._UpdateBreakpoints, l:new)
  return l:new
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @public
" @dict Source
" Return the short name of this source if present, or |v:null| if not.
function! dapper#model#Source#name() dict abort
  call s:CheckType(l:self)
  return get(l:self._raw_source, 'name', v:null)
endfunction

""
" @public
" @dict Source
" Return the path to this source on disk if present, or |v:null| if not.
function! dapper#model#Source#path() dict abort
  call s:CheckType(l:self)
  return get(l:self._raw_source, 'path', v:null)
endfunction

""
" @public
" @dict Source
" Return the sourceReference of this source if present, or |v:null| if not.
function! dapper#model#Source#sourceReference() dict abort
  call s:CheckType(l:self)
  return get(l:self._raw_source, 'sourceReference', v:null)
endfunction

""
" @public
" @dict Source
" Return the presentationHint of this source if present, or |v:null| if not.
function! dapper#model#Source#presentationHint() dict abort
  call s:CheckType(l:self)
  return get(l:self._raw_source, 'presentationHint', v:null)
endfunction

""
" @public
" @dict Source
" Return the origin of this source if present, or |v:null| if not.
function! dapper#model#Source#origin() dict abort
  call s:CheckType(l:self)
  return get(l:self._raw_source, 'origin', v:null)
endfunction

""
" @public
" @dict Source
" Return a list of sources related to this source if present, or |v:null| if
" none could be found.
function! dapper#model#Source#sources() dict abort
  call s:CheckType(l:self)
  return get(l:self._raw_source, 'sources', v:null)
endfunction

""
" @public
" @dict Source
" Return this source's `adapterData` if present, or |v:null| if not.
function! dapper#model#Source#adapterData() dict abort
  call s:CheckType(l:self)
  return get(l:self._raw_source, 'adapterData', v:null)
endfunction

""
" @public
" @dict Source
" Return the checksums associated with the source file if present, or
" |v:null| if not.
function! dapper#model#Source#checksums() dict abort
  call s:CheckType(l:self)
  return get(l:self._raw_source, 'checksums', v:null)
endfunction

""
" @public
" @dict Source
" Return the absolute path to this source's file on disk.
"
" @throws NotFound if this source has a nonzero `sourceReference` and cannot be found on disk.
function! dapper#model#Source#AbsolutePath() dict abort
  call s:CheckType(l:self)
  let l:to_return = l:self.path()
  if !l:to_return
    throw maktaba#error#NotFound(
        \ 'Could not find path for Source: %s', l:self.name())
  endif
  " TODO more advanced path resolution?
  return l:to_return
endfunction

""
" @public
" @dict Source
" Return a |TypeVim.Promise| resolving to the contents of this Source as a
" list of strings, one string per line.
"
" @throws NotFound if this source has an associated path or (equivalently) has no `sourceReference`.
function! dapper#model#Source#Contents() dict abort
  call s:CheckType(l:self)
endfunction

""
" @public
" @dict Source
" Set {breakpoint} on this Source. Returns a |TypeVim.Promise| that resolves
" to a list of all `DebugProtocol.Breakpoint`s on this Source.
"
" @throws BadValue if {breakpoint} is not a dict.
" @throws WrongType if {breakpoint} is not a `DebugProtocol.SourceBreakpoint`.
function! dapper#model#Source#SetBreakpoint(breakpoint) dict abort
  call s:CheckType(l:self)
  call typevim#ensure#Implements(a:breakpoint, dapper#dap#SourceBreakpoint())
endfunction

function! dapper#model#Source#RemoveBreakpoint() dict abort
  call s:CheckType(l:self)
endfunction

""
" @public
" @dict Source
" Update the contents of this Source from a DebugProtocol.SourceResponse and
" return it.
function! dapper#model#Source#_UpdateContents(msg) dict abort
  call s:CheckType(l:self)
  call typevim#ensure#Implements(a:msg, dapper#dap#SourceResponse())
  if !a:msg.success
    throw maktaba#error#Failure(
        \ 'Failed to retrieve contents for: %s', l:self.name())
  endif
  let l:body = a:msg.body
  let l:self._mime_type = l:body.mimeType
  let l:content_as_list = typevim#string#Listify(l:body.content)
  let l:self.content = l:content_as_list
  return l:content_as_list
endfunction

function! dapper#model#Source#_UpdateBreakpoints(msg) dict abort
  call s:CheckType(l:self)
  call typevim#ensure#Implements(a:msg, dapper#dap#SetBreakpointsResponse())
  if !a:msg.success
    throw maktaba#error#Failure(
        \ 'Failed to set breakpoints for: %s', l:self.name())
  endif
endfunction
      " \ 'AbsolutePath': typevim#make#Member('AbsolutePath'),
      " \ 'Contents': typevim#make#Member('Contents'),
      " \ 'SetBreakpoint': typevim#make#Member('SetBreakpoint'),
      " \ 'RemoveBreakpoint': typevim#make#Member('RemoveBreakpoint'),
