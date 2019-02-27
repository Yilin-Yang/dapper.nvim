""
" @dict DapperReport
" @private
" Construct a DapperReport object.
" @usage []
function! dapper#dap#DapperReport#New(...) abort
  let l:interface = dapper#dap#DapperReport()
  let l:new = typevim#make#Instance(l:interface)
  let l:new.kind  = maktaba#ensure#IsString(get(a:000, 0, ''))
  let l:new.brief = maktaba#ensure#IsString(get(a:000, 1, ''))

  let l:long = get(a:000, 2, '')
  if !maktaba#value#IsString(l:long)
    let l:long = typevim#object#PrettyPrint(l:long)
  endif
  let l:new.long  = l:long

  let l:other = get(a:000, 3, '')
  if !maktaba#value#IsString(l:other)
    let l:other = typevim#object#PrettyPrint(l:other)
  endif
  let l:new.other = l:other

  return typevim#ensure#Implements(l:new, l:interface)
endfunction
