""
" @public
" @dict DapperReport
" @function dapper#dap#DapperReport#New([kind], [brief], [Long], [Other])
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
  let l:new.type = 'report'
  let l:new.kind = l:kind
  let l:new.brief = l:brief
  let l:new.long = get(a:000, 2, '')
  let l:new.other = get(a:000, 3, '')

  " autopopulate vim_msg_typename
  let l:new.vim_msg_typename = toupper(l:kind[0:0]).l:kind[1:].'Report'

  " return typevim#ensure#Implements(l:new, l:interface)  " check is redundant
  return l:new
endfunction
let s:log_levels = dapper#constants#LOG_LEVELS()
