""
" @private
" @dict DebugLogger
" A global debug logger. Writes incoming @dict(Report)s to a log buffer and,
" optionally, a logfile just before vim exits.
"
" Is a wrapper around dapper.nvim's maktaba-provided plugin-wide debug logger.

let s:plugin = maktaba#plugin#Get('dapper.nvim')
let s:typename = 'DebugLogger'

""
" @dict DebugLogger
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

  let l:base = typevim#Buffer#New({
        \ 'bufhidden': 'hide',
        \ 'buflisted': 0,
        \ 'bufname': s:plugin.flags.log_buffer_name.Get(),
        \ 'buftype': 'nofile',
        \ 'swapfile': 0,
      \ })
  let l:new = {
      \ '__logger': g:dapper_plugin.logger,
      \ 'Log': typevim#make#Member('Log'),
      \ 'NotifyReport': typevim#make#Member('NotifyReport'),
      \ }

  call typevim#make#Derived(
      \ s:typename, l:base, l:new, typevim#make#Member('CleanUp'))

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
" @dict DebugLogger
" Write the debug log to an output file, if configured to do so.
function! dapper#log#DebugLogger#CleanUp() dict abort
  call s:CheckType(l:self)
  if s:plugin.flags.log_buffer_writeback.Get()
    let l:buf_contents = l:self.GetLines(1, -1)
    " synchronously write to the logfile
    call writefile(l:buf_contents, s:plugin.flags.logfile.Get(), 's')
  endif
endfunction

""
" Append text to the debug log buffer.
function! dapper#log#DebugLogger#Log() dict abort
  " TODO what function signature?
endfunction

""
" @dict DebugLogger
" Send a report, which which might be logged by a handler.
"
" {kind} is the type of report. These correspond one-to-one with the
" |maktaba.Logger| log levels.
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
" @throws WrongType if {kind} or {brief} are not strings.
function! dapper#log#DebugLogger#NotifyReport(kind, brief, ...) dict abort
  call s:CheckType(l:self)
  call maktaba#ensure#IsString(a:kind)
  call maktaba#ensure#IsString(a:brief)
  let l:long = ''
  let l:other = ''
  if a:0 >=# 2
    let l:other = typevim#object#PrettyPrint(get(a:000, 1))
  elseif a:0 ==# 1
    let l:long = typevim#object#PrettyPrint(get(a:000, 0))
  endif

  " TODO
endfunction
