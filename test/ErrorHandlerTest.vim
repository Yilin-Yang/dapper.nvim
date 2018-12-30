" NOTES:  For testing ReportHandler echo behavior, which can't be feasibly
"         tested using Vader, since we can't close out the echo prompts using
"         `feedkeys`.
"
" USAGE:  Run `./run_tests_nvim.sh -v`, then `:source ErrorHandlerTest.vim`.
"         Edit the echo message options and the entries in `g:msg` as
"         needed.

let g:eh = dapper#log#ErrorHandler#new(g:db, g:dapper_middletalker)
let g:msg = {
  \ 'vim_msg_typename':'ErrorReport',
  \ 'vim_id':0,
  \ 'type':'report',
  \ 'kind':'error',
  \ 'brief': 'foobar',
  \ 'long':'foobarfoobar',
  \ 'alert':1
  \ }
call g:dapper_middletalker.receive(g:msg)
