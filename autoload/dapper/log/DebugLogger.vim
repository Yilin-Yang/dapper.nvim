""
" @dict DebugLogger
" A global debug logger. Writes incoming @dict(DapperReport)s to a log buffer
" and, optionally, a logfile just before vim exits.
"
" Is a wrapper around dapper.nvim's maktaba-provided plugin-wide debug logger.
"
" Public member variables include `buffer`, which is the |TypeVim.Buffer|
" object wrapping the DebugLogger's log buffer.

let s:plugin = maktaba#plugin#Get('dapper.nvim')
let s:typename = 'DebugLogger'

let s:report_interface = dapper#dap#DapperReport()

""
" @public
" @dict DebugLogger
" @function dapper#log#DebugLogger#Interface()
" Returns the interface that DebugLogger implements.
function! dapper#log#DebugLogger#Interface() abort
  if !exists('s:interface')
    let s:interface = {
        \ 'Log': typevim#Func(),
        \ 'NotifyReport': typevim#Func(),
        \ }
    call typevim#make#Interface(s:typename, s:interface)
  endif
  return s:interface
endfunction
call dapper#log#DebugLogger#Interface()

""
" @public
" @dict DebugLogger
" Return a reference to the DebugLogger singleton.
function! dapper#log#DebugLogger#Get() abort
  if exists('g:dapper_debug_logger')
    try
      call typevim#ensure#IsType(g:dapper_debug_logger)
      call typevim#ensure#Implements(g:dapper_debug_logger, s:interface)
      " is valid object
      return g:dapper_debug_logger
    catch
      " fall through
      unlet g:dapper_debug_logger
    endtry
  endif

  let l:buffer = typevim#Buffer#New({
        \ 'bufhidden': 'hide',
        \ 'buflisted': 0,
        \ 'bufname': s:plugin.flags.log_buffer_name.Get(),
        \ 'buftype': 'nofile',
        \ 'swapfile': 0,
      \ })
  let l:new = {
      \ 'buffer': l:buffer,
      \ '__logger': g:dapper_plugin.logger,
      \ 'Log': typevim#make#Member('Log'),
      \ 'ListifyReport': typevim#make#Member('ListifyReport'),
      \ 'NotifyReport': typevim#make#Member('NotifyReport'),
      \ }

  call typevim#make#Class(s:typename, l:new, typevim#make#Member('CleanUp'))

  let g:dapper_debug_logger = l:new

  augroup dapper_debug_logger
    au!
    autocmd VimLeave * call g:dapper_debug_logger.CleanUp()
  augroup end

  return g:dapper_debug_logger
endfunction

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @public
" @dict DebugLogger
" Write the debug log to an output file, if configured to do so.
function! dapper#log#DebugLogger#CleanUp() dict abort
  call s:CheckType(l:self)
  if s:plugin.flags.log_buffer_writeback.Get()
    let l:buf_contents = l:self.buffer.GetLines(1, -1)
    " synchronously write to the logfile
    call writefile(l:buf_contents, s:plugin.flags.logfile.Get(), 's')
  endif
endfunction

""
" @public
" @dict DebugLogger
" Append a {report} to the dapper-specific debug log.
"
" Does not log to dapper.nvim's maktaba debugger interface. For that, see
" @function(DebugLogger.NotifyReport).
"
" @throws BadValue if the given {report} is not a dict.
" @throws WrongType if the given {report} is not a @dict(DapperReport).
function! dapper#log#DebugLogger#Log(report) dict abort
  if exists('*strftime')
    let l:timestamp = strftime('%F %T (%a, %e %B)')
  else
    let l:timestamp = localtime()
  endif
  let l:lines_to_append = [
      \ l:timestamp,
      \ ]
  let l:report = l:self.ListifyReport(a:report)

  call append(l:lines_to_append, l:report)
  call l:self.buffer.InsertLines('$', l:lines_to_append)
endfunction

""
" @public
" @dict DebugLogger
" Convert the given {report} instance into a list printable through
" functions like |append()| and return it.
"
" @throws BadValue if {report} is not a dict.
" @throws WrongType if {report} is not a @dict(DapperReport) object.
function! dapper#log#DebugLogger#ListifyReport(report) dict abort
  call typevim#ensure#Implements(a:report, s:report_interface)

  let l:lines_to_append = [
      \ 'report: { '.a:report.kind.', '.a:report,
      \ ]

  " convert 'raw' strings into an indented, listified format
  let l:indent_block = '  '
  if empty(a:report.long)
    let l:long = []
  else
    let l:long = typevim#string#IndentList(
        \ typevim#string#Listify(a:report.long), l:indent_block)
    let l:long[0] = l:indent_block.'long: '.l:long[0]
  endif
  if empty(a:report.other)
    let l:long = []
  else
    let l:other = typevim#string#IndentList(
        \ typevim#string#Listify(a:report.other), l:indent_block)
    let l:other[0] = l:indent_block.'other:  '.l:other[0]
  endif

  call add(l:lines_to_append, l:long)
  call add(l:lines_to_append, l:other)
  call add(l:lines_to_append, '}')

  return l:lines_to_append
endfunction

""
" @public
" @dict DebugLogger
" Make a report. Log it to dapper.nvim's maktaba logger interface, which might
" shout the message at the user. Also append it to the debug log.
"
" {kind} is the type of report. These correspond one-to-one with the
" |maktaba.Logger| log levels. This is not case sensitive.
"
" {brief} is a short (50 characters or less) summary of the report. If this is
" longer than 50 characters, it will be truncated automatically.
"
" [long] is the verbose content of the message.
"
" [other] is any other miscellaneous information about the report.
"
" All optional arguments are pretty-printed into strings, regardless of their
" original type.
"
" @throws BadValue if {kind} is not a |maktaba.Logger| level.
" @throws WrongType if {kind} or {brief} are not strings.
function! dapper#log#DebugLogger#NotifyReport(kind, brief, ...) dict abort
  call s:CheckType(l:self)
  let l:brief = maktaba#ensure#IsString(a:brief)[:49]
  let l:kind_lower = tolower(maktaba#ensure#IsString(a:kind))
  let l:kind_func = toupper(l:kind_lower[0:0]).l:kind_lower[1:]

  " log to dapper.nvim's internal debug log
  let l:report = call('dapper#dap#DapperReport', [a:kind, a:brief] + a:000)
  call l:self.Log(l:report)

  " log to the maktaba logger interface
  " note that the log levels are also the names of dict functions inside the
  " maktaba logger object (see `:help maktaba.Logger`)
  call l:self.__logger[l:kind_func](l:brief)
endfunction
