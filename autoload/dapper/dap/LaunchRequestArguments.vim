""
" @dict LaunchRequestArguments
" A Debug Adapter Protocol type used for starting a debugger process.
" Properties are specific to a given debug adapter's implementation.

""
" @public
" @dict LaunchRequestArguments
" @function dapper#dap#LaunchRequestArguments#new()
" Construct and return a skeletal LaunchRequestArguments object.
function! dapper#dap#LaunchRequestArguments#new() abort
  let l:new = {
    \ 'noDebug': v:false,
    \ '__restart': {},
  \ }
  return typevim#make#Class('LaunchRequestArguments', l:new)
endfunction
