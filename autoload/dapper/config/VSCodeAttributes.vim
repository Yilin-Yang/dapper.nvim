""
" @dict VSCodeAttributes
" Settings from a `launch.json` that normally control VSCode-specific
" behavior, e.g.  `"preLaunchTask"`, `"postLaunchTask"`,
" `"internalConsoleOptions"` and `"debugServer"`.

let s:typename = 'VSCodeAttributes'

""
" @public
" @dict VSCodeAttributes
" @function dapper#config#VSCodeAttributes#new()
" Construct and return a VSCodeAttributes object.
function! dapper#config#VSCodeAttributes#new() abort
  let l:new = {
      \ 'preLaunchTask': '',
      \ 'postLaunchTask': '',
      \ 'internalConsoleOptions': '',
      \ 'debugServer': '',
      \ }
  return typevim#make#Class(s:typename, l:new)
endfunction
