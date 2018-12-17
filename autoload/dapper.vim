" BRIEF:  Receive a response or event from the TypeScript middle-end.
function! dapper#receive(msg) abort
  call g:dapper_middletalker.receive(a:msg)
endfunction
