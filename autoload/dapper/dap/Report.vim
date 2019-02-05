""
" @dict Report
" Report is a "fake" DAP message type, i.e. a message that is not formally
" part of the DAP specification. It is a "DAP-esque" message type used to
" relay status updates and error messages to the user, either by echoing it to
" the statusline, or just by printing it to a logfile.

""
" @public
" @function dapper#dap#Report#new([vim_id], [vim_msg_typename], [kind], [brief], [long], [alert], [other])
" @dict Report
" @usage
" Construct and return a new Report object.
"
" [kind] is the "type" of Report. As of the time of writing, possible values
" of [kind] include `"status"` and `"error"`.
"
" [brief] is a short (50 characters or fewer) summary of the message. The size
" restriction is imposed so that echoing the [brief] message will not wrap to
" a second line, forcing the user to |hit-enter| to clear the message if its
" displayed.
"
" [long] is a longer description of the problem. It may be of any type (list,
" dictionary, etc.), since it will be pretty-printed into a string before
" being shown or logged.
"
" [alert] is a boolean value, either 0 or 1, with a value of 1 indicating that
" the report should be shouted at the user. Whether this actually occurs
" depends on the [kind] of report, and on the user's settings.
"
" [other] is anything else that might be importance. Like [long], it may be of
" any datatype.
"
" [vim_id] should essentially always be 0.
" If [vim_msg_typename] is empty, the Report object will be given an
" autogenerated `"vim_msg_typename"`. In practice, there's no reason not to
" specify an empty string.
"
" @throws BadValue if [kind] is not `"status"` or `"error"`.
" @throws WrongType if [vim_id] is not a number, [vim_msg_typename] is not a string, [kind] or [brief] are not strings, or if [alert] is not a boolean value.
function! dapper#dap#Report#new(...)
  let a:vim_msg_typename = maktaba#ensure#IsString(get(a:000, 1, ''))
  let a:kind  = maktaba#ensure#IsString(get(a:000, 2, ''))
  let a:brief = maktaba#ensure#IsString(get(a:000, 3, ''))
  let a:long  = get(a:000, 4, '')
  let a:alert = typevim#ensure#IsBool(get(a:000, 5, 0))
  let a:other = get(a:000, 6, '')

  call maktaba#ensure#IsIn(a:kind, ['status', 'error'])

  let l:new = {
      \ 'type':  'report',
      \ 'kind':  a:kind,
      \ 'brief': a:brief,
      \ 'long':  a:long,
      \ 'alert': a:alert,
      \ 'other': a:other,
      \ }

  if a:kind !=# '' && a:vim_msg_typename ==# ''
    let l:new['vim_msg_typename'] = toupper(a:kind[0:0]).a:kind[1:].'Report'
  endif

  return typevim#make#Derived(
      \ 'Report', call('dapper#dap#ProtocolMessage#new', a:000), l:new)
endfunction
