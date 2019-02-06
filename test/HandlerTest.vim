" NOTES:  For testing ReportHandler echo behavior, which can't be feasibly
"         tested using Vader, since we can't close out the echo prompts using
"         `feedkeys`.
"
" USAGE:  Run `./run_tests_nvim.sh -v`, then `:source HandlerTest.vim`.
"         Edit the echo message options and the entries in `g:*_msg` as
"         needed.

" let g:eh = dapper#log#ErrorHandler#new(g:dapper_debug_logger, g:dapper_middletalker)
" let g:err_msg = {
"   \ 'vim_msg_typename':'ErrorReport',
"   \ 'vim_id':0,
"   \ 'type':'report',
"   \ 'kind':'error',
"   \ 'brief': 'error',
"   \ 'long':'errorerror',
"   \ 'alert':1
"   \ }
" call g:dapper_middletalker.Receive(g:err_msg)


let g:dapper_echo_messages = 'statuses'
let g:sh = dapper#log#StatusHandler#new(g:dapper_debug_logger, g:dapper_middletalker)
let g:sta_msg = {
  \ 'vim_msg_typename':'StatusReport',
  \ 'vim_id':0,
  \ 'type':'report',
  \ 'kind':'status',
  \ 'brief': 'status',
  \ 'long':'statusstatus',
  \ 'alert':1
  \ }
call g:dapper_middletalker.Receive(g:sta_msg)
