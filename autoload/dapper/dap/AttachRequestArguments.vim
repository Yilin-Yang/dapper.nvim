""
" @dict AttachRequestArguments
" A Debug Adapter Protocol type used for attaching to a running debugger
" process. Properties are specific to a given debug adapter's implementation.

""
" @public
" @dict AttachRequestArguments
" @function dapper#dap#AttachRequestArguments#new()
" Construct and return a skeletal AttachRequestArguments object.
function! dapper#dap#AttachRequestArguments#new() abort
  let l:new = {
    \ '__restart': {},
  \ }
  return typevim#make#Class('AttachRequestArguments', l:new)
endfunction
