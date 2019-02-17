""
" @private
" @dict DebugLogger
" A global debug logger. Writes incoming @dict(Report)s to a log buffer and,
" optionally, a logfile.

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

" BRIEF:  Get a reference to the debug logger singleton.
function! dapper#log#DebugLogger#Get(...) abort
  if exists('g:dapper_debug_logger')
    try
      call dapper#log#DebugLogger#CheckType(g:dapper_debug_logger)
      return g:dapper_debug_logger
    catch
      " invalid, okay to overwrite
    endtry
  endif

  let l:bufset = {
      \ 'bufname': dapper#settings#Logfile(),
      \ 'bufhidden': 'hide',
      \ 'buflisted': 0,
      \ 'buftype' : 'nofile',
      \ 'swapfile': 1,
      \ }

  let l:writeback = dapper#settings#LogBufferWriteback()

  " set initial 'last line written' to 1, so that we ignore the blank line
  " at the top of the log buffer when writing back
  let l:new = {
      \ '__writeback': l:writeback,
      \ '__settings': l:bufset,
      \ '__counter': -1,
      \ '__last_line_written': 1,
      \ '__ShouldWrite': typevim#make#Member('__ShouldWrite'),
      \ '__Write': typevim#make#Member('__Write'),
      \ 'Log': typevim#make#Member('Log'),
      \ 'NotifyReport': typevim#make#Member('NotifyReport'),
      \ }
  let l:base = typevim#Buffer#New(l:bufset)
  call typevim#make#Derived(
      \ s:typename, l:base, l:new, typevim#make#Member('CleanUp'))
  let g:dapper_debug_logger = l:new
  if !$IS_DAPPER_DEBUG
  augroup dapper_debug_logger
    au!
    " this autocommand causes nvim to throw a 'Press ENTER or type command to
    " continue' message when running test cases in the terminal (i.e. without
    " a GUI). The IS_DAPPER_DEBUG check exists *just* to prevent those tests
    " from hanging.
    autocmd VimLeavePre * call g:dapper_debug_logger.CleanUp()
  augroup end
  endif

  return typevim#ensure#Implements(
      \ g:dapper_debug_logger, dapper#log#DebugLogger#Interface())
endfunction

""
" @dict DebugLogger
" Returns a dummy logger, with the same interface as the actual debug
" logger, but which does nothing when its functions are invoked.
function! dapper#log#DebugLogger#Dummy() abort
  return typevim#make#Instance(dapper#log#DebugLogger#Interface())
endfunction

function! s:DoNothing(...) abort dict
endfunction

" NOTE: Setting `buftype=nofile` in *all* cases is a hack.
"       When writing back, we use `writefile()` in order to save the log
"       buffer in the background, without opening it directly; but this
"       doesn't reset the `&modified` flag for the log buffer, so nvim will
"       complain about unsaved buffers when exiting with `:q` or `:qa`.
"       Setting `nofile` prevents that.
let s:writeback_to_bufsettings = {
    \ 'never': {
        \ 'bufname': dapper#settings#LogBufferName(),
        \ 'bufhidden': 'hide',
        \ 'buflisted': 0,
        \ 'buftype' : 'nofile',
        \ 'swapfile': 0,
        \ },
    \ 'onclose': {
        \ 'bufname': dapper#settings#Logfile(),
        \ 'bufhidden': 'hide',
        \ 'buflisted': 0,
        \ 'buftype' : 'nofile',
        \ 'swapfile': 0,
        \ },
    \ }

function! s:CheckType(Obj) abort
  call typevim#ensure#IsType(a:Obj, s:typename)
endfunction

""
" @dict DebugLogger
" Returns 1 if the DebugLogger should write the next message it receives.
function! dapper#log#DebugLogger#__ShouldWrite() abort dict
  call s:CheckType(l:self)
  let l:wb = l:self.__writeback
  return l:wb ==# 'always'
endfunction

""
" @dict DebugLogger
" Write the contents of the debug logger to a file.
function! dapper#log#DebugLogger#__Write() abort dict
  call s:CheckType(l:self)
  let l:from = l:self.__last_line_written
  let l:bufnr = l:self.__bufnr
  let l:to_writeback = nvim_buf_get_lines(l:bufnr, l:from, -1, 1)
  let l:bufname = l:self.__settings.bufname
  " synchronously append to file
  call writefile(l:to_writeback, l:bufname, 'as')
  let l:self.__last_line_written += len(l:to_writeback)
endfunction

""
" @dict DebugLogger
" Perform last-minute cleanup, execute writebacks before closing vim.
function! dapper#log#DebugLogger#CleanUp() abort dict
  call s:CheckType(l:self)
  let l:writeback = l:self.__writeback
  if l:writeback ==# 'onclose' || l:writeback ==# 'always'
    call l:self.__Write()
  endif
endfunction

""
" @dict DebugLogger
" Append {text}, either a single line, or a list of lines, to the end of the
" log buffer.
"
" [type] is the type of the message, and its value controls the prefix
" prepended to the message text, which affects the message's syntax
" highlighting in the log buffer.
"
" @default type="status"
" @throws BadValue if [type] is not a valid message type.
" @throws WrongType if {text} is not a string or list, or if [type] is not a string.
let s:types_to_prefixes = {
    \ 'error':  '[ERROR]',
    \ 'status': '[NORMAL]',
    \ }
let s:types_to_term_prefixes = {
    \ 'error':  '[/E]',
    \ 'status': '[/N]',
    \ }
let s:body_indent = '  '
function! dapper#log#DebugLogger#Log(text, ...) abort dict
  call s:CheckType(l:self)
  call maktaba#ensure#TypeMatchesOneOf(a:text, ['', []])
  let l:type = maktaba#ensure#IsString(get(a:000, 0, 'status'))
  call maktaba#ensure#IsIn(l:type, keys(s:types_to_prefixes))
  if type(a:text) ==# v:t_list
    let l:to_insert = a:text
  elseif type(a:text) ==# v:t_string
    let l:to_insert = [a:text]
  else
    let l:to_insert = [string(a:text)]
  endif

  let l:prefix = s:types_to_prefixes[l:type]
  let l:term_pfx = s:types_to_term_prefixes[l:type]
  try
    if exists('*strftime')
      let l:ts = strftime('%c')
    else
      throw ''
    endif
  catch
    let l:ts = localtime()
  endtry

  let l:to_insert = [l:ts.': '.l:prefix] + l:to_insert
  let l:i = 1 | while l:i < len(l:to_insert)
    let l:to_insert[l:i] = s:body_indent.l:to_insert[l:i]
  let l:i += 1 | endwhile
  let l:to_insert += [l:term_pfx]
  call l:self.InsertLines(-1, l:to_insert)

  let l:self.__counter += 1  " received another message
  if l:self.__ShouldWrite()  " based on the current received count,
    call l:self.__Write()
  endif
endfunction

""
" @dict DebugLogger
" Send a report, which might be logged by a handler.
function! dapper#log#DebugLogger#NotifyReport(kind, brief, ...) abort dict
  call s:CheckType(l:self)
  let l:msg = call('dapper#dap#Report#new', [0, '', a:kind, a:brief] + a:000)
  call dapper#receive(l:msg)
endfunction
