""
" @dict VSCodeAttributes
" Settings from a `launch.json` that normally control VSCode-specific
" behavior, e.g.  `"preLaunchTask"`, `"postLaunchTask"`,
" `"internalConsoleOptions"` and `"debugServer"`.

let s:typename = 'VSCodeAttributes'

" @public
" @dict VSCodeAttributes
" @function dapper#config#VSCodeAttributes#Interface()
function! dapper#config#VSCodeAttributes#Interface() abort
  if !exists('s:interface')
    " TODO what possible internalConsoleOptions are there?
    let s:interface = {
        \ 'preLaunchTask?': typevim#String(),
        \ 'postLaunchTask?': typevim#String(),
        \ 'internalConsoleOptions?': typevim#String(),
        \ 'debugServer?': typevim#Number(),
        \ }
    call typevim#make#Interface(s:typename, s:interface)
  endif
  return s:interface
endfunction

""
" @public
" @dict VSCodeAttributes
" @function dapper#config#VSCodeAttributes#New([prelaunch] [postlaunch] [console_opt] [debugserver])
" Construct and return a VSCodeAttributes object.
"
" [prelaunch] is a "preLaunchTask"; [postlaunch] is a "postLaunchTask";
" [console_opt] are "internalConsoleOptions"; and [debug_server] is a
" [debugServer] port number.
function! dapper#config#VSCodeAttributes#New(...) abort
  let l:prelaunch    = get(a:000, 0, v:null)
  let l:postlaunch   = get(a:000, 1, v:null)
  let l:console_opt  = get(a:000, 2, v:null)
  let l:debug_server = get(a:000, 3, v:null)
  let l:new = {}
  if l:prelaunch isnot v:null
    let l:new.preLaunchTask = l:prelaunch
  endif
  if l:postlaunch isnot v:null
    let l:new.postLaunchTask = l:postlaunch
  endif
  if l:console_opt isnot v:null
    let l:new.console_opt = l:console_opt
  endif
  if l:debug_server isnot v:null
    let l:new.debug_server = l:debug_server
  endif
  call typevim#make#Class(s:typename, l:new)
  return typevim#ensure#Implements(
      \ l:new, dapper#config#VSCodeAttributes#Interface())
endfunction
