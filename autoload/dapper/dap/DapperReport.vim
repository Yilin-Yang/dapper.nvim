""
" @public
" @dict DapperReport
" @usage [kind] [brief] [Long] [Other]
"
" Construct a DapperReport object.
"
" [Long] and [Other] may both be non-string objects; if they are, then they
" will be pretty-printed to strings on construction.
function! dapper#dap#DapperReport#New(...) abort
  let l:kind  = tolower(maktaba#ensure#IsString(get(a:000, 0, '')))
  let l:brief = maktaba#ensure#IsString(get(a:000, 1, '')[0:49])
  call maktaba#ensure#IsIn(l:kind, s:log_levels)

  let l:interface = dapper#dap#DapperReport()
  let l:new = typevim#make#Instance(l:interface)
  let l:new.kind = l:kind
  let l:new.brief = l:brief

  let l:Long = get(a:000, 2, '')
  let l:new.long = maktaba#value#IsString(l:Long) ?
      \ l:Long : typevim#object#PrettyPrint(l:Long)

  let l:Other = get(a:000, 3, '')
  let l:new.other = maktaba#value#IsString(l:Other) ?
      \ l:Other : typevim#object#PrettyPrint(l:Other)

  " autopopulate vim_msg_typename
  let l:new.vim_msg_typename = toupper(l:kind[0:0]).l:kind[1:].'Report'

  return typevim#ensure#Implements(l:new, l:interface)
endfunction
let s:log_levels = ['debug', 'info', 'warn', 'error', 'severe']
