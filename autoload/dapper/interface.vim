let s:typename_to_interface = {}

""
" @public
" Return an interface for an "update pusher" object, an object that may exist
" in a tree, which may accept updates from a parent and push updates to
" children.
function! dapper#interface#UpdatePusher() abort
  let l:typename = 'UpdatePusher'
  if !has_key(s:typename_to_interface, l:typename)
    let l:interface = {
        \ 'GetParent': typevim#Func(),
        \ 'SetParent': typevim#Func(),
        \ 'AddChild': typevim#Func(),
        \ 'RemoveChild': typevim#Func(),
        \ 'GetChildren': typevim#Func(),
        \ 'Push': typevim#Func(),
        \ }
    call typevim#make#Interface(l:typename, l:interface)
    let s:typename_to_interface[l:typename] = l:interface
  endif
  return s:typename_to_interface[l:typename]
endfunction
