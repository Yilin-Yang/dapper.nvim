" BRIEF:  Global singleton debug logger.

" BRIEF:  Get a reference to the debug logger singleton.
function! dapper#log#DebugLogger#get(...) abort
  if exists('g:dapper_debug_logger')
    try
      call dapper#log#DebugLogger#CheckType(g:dapper_debug_logger)
    catch
      " invalid, okay to overwrite
    endtry
    return g:dapper_debug_logger
  endif

  let l:writeback = dapper#settings#LogBufferWriteback()
  if match(l:writeback, 'every') !=# -1
    let l:every = split(l:writeback, 'every')[0] + 0
    let l:writeback = 'every'
    let l:bufset = s:writeback_to_bufsettings[l:writeback]
    let l:bufset['interval'] = l:every
  else
    let l:bufset = s:writeback_to_bufsettings[l:writeback]
  endif

  " create log buffer, set settings
  let l:new = dapper#view#Buffer#new(l:bufset)
  let l:new['TYPE']['DebugLogger'] = 1
  let l:new['__writeback'] = l:writeback
  let l:new['__settings'] = l:bufset
  let l:new['__counter'] = -1
  " set iniital 'last line written' to 1, so that we ignore the blank line
  " at the top of the log buffer when writing back
  let l:new['__last_line_written'] = 1
  let l:new['__shouldWrite'] =
      \ function('dapper#log#DebugLogger#__shouldWrite')
  let l:new['__write'] = function('dapper#log#DebugLogger#__write')
  let l:new['__onExit'] = function('dapper#log#DebugLogger#__onExit')
  let l:new['log'] = function('dapper#log#DebugLogger#log')
  let l:new['notifyReport'] = function('dapper#log#DebugLogger#notifyReport')

  let g:dapper_debug_logger = l:new

  if !$IS_DAPPER_DEBUG
  augroup dapper_debug_logger
    au!
    " this autocommand causes nvim to throw a 'Press ENTER or type command to
    " continue' message when running test cases in the terminal (i.e. without
    " a GUI). The IS_DAPPER_DEBUG check exists *just* to prevent those tests
    " from hanging.
    autocmd VimLeavePre * call g:dapper_debug_logger.__onExit()
  augroup end
  endif

  return g:dapper_debug_logger
endfunction

" RETURNS:  A 'dummy' logger, with the same interface as the actual debug
"     logger, but which does nothing when its functions are invoked.
function! dapper#log#DebugLogger#dummy() abort
  return {
      \ 'log': funcref('<SID>DoNothing'),
      \ 'notifyReport': funcref('<SID>DoNothing'),
      \ }
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
        \ 'fname': dapper#settings#LogBufferName(),
        \ 'bufhidden': 'hide',
        \ 'buflisted': v:false,
        \ 'buftype' : 'nofile',
        \ 'swapfile': v:false,
        \ },
    \ 'onclose': {
        \ 'fname': dapper#settings#Logfile(),
        \ 'bufhidden': 'hide',
        \ 'buflisted': v:false,
        \ 'buftype' : 'nofile',
        \ 'swapfile': v:false,
        \ },
    \ 'every': {
        \ 'fname': dapper#settings#Logfile(),
        \ 'bufhidden': 'hide',
        \ 'buflisted': v:false,
        \ 'buftype' : 'nofile',
        \ 'swapfile': v:true,
        \ 'interval': -1,
        \ },
    \ 'always': {
        \ 'fname': dapper#settings#Logfile(),
        \ 'bufhidden': 'hide',
        \ 'buflisted': v:false,
        \ 'buftype' : 'nofile',
        \ 'swapfile': v:true,
      \ }
    \ }

function! dapper#log#DebugLogger#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'DebugLogger')
  try
    let l:err = '(dapper#log#DebugLogger) Object is not of type DebugLogger: '.string(a:object)
  catch
    redir => l:object
    silent! echo a:object
    redir end
    let l:err = '(dapper#log#DebugLogger) This object failed type check: '.l:object
  endtry
  throw l:err
  endif
endfunction

" RETURNS:  `v:true` if the DebugLogger should write the next message it
"           receives.
function! dapper#log#DebugLogger#__shouldWrite() abort dict
  call dapper#log#DebugLogger#CheckType(l:self)
  let l:wb = l:self['__writeback']
  if l:wb ==# 'always'
    return v:true
  endif
  if l:wb !=# 'every' | return v:false | endif
  let l:counter = l:self['__counter']
  let l:interval = l:self['__settings']['interval']
  return !float2nr(fmod(l:counter, l:interval))
endfunction

" BRIEF:  Write the contents of the debug logger to a file.
function! dapper#log#DebugLogger#__write() abort dict
  call dapper#log#DebugLogger#CheckType(l:self)
  let l:from = l:self['__last_line_written']
  let l:bufnr = l:self['__bufnr']
  let l:to_writeback = nvim_buf_get_lines(l:bufnr, l:from, -1, v:true)
  let l:fname = l:self['__settings']['fname']
  " asynchronously append to file
  call writefile(l:to_writeback, l:fname, 'aS')
  let l:self['__last_line_written'] += len(l:to_writeback)
endfunction

" BRIEF:  Perform last-minute cleanup, execute writebacks before closing vim.
function! dapper#log#DebugLogger#__onExit() abort dict
  call dapper#log#DebugLogger#CheckType(l:self)
  let l:writeback = l:self['__writeback']
  if l:writeback ==# 'onclose' || l:writeback ==# 'always'
    call l:self.__write()
  endif
endfunction

" BRIEF:  Append text to the debug log.
" PARAMS: text  (v:t_string|v:t_list) A single line, or a list of lines to be
"                                     appended to the log buffer.
" PARAMS: type  (v:t_string)  The type of the message. Controls the prefix that
"                             is prepended the message text, which affects the
"                             message's syntax highlighting.
let s:types_to_prefixes = {
    \ 'error':  '[ERROR]',
    \ 'status': '[NORMAL]',
    \ }
let s:types_to_term_prefixes = {
    \ 'error':  '[/E]',
    \ 'status': '[/N]',
    \ }
let s:body_indent = '  '
function! dapper#log#DebugLogger#log(text, ...) abort dict
  call dapper#log#DebugLogger#CheckType(l:self)
  let a:type = get(a:000, 0, 'status')
  if type(a:text) ==# v:t_list
    let l:to_insert = a:text
  elseif type(a:text) ==# v:t_string
    let l:to_insert = [a:text]
  else
    let l:to_insert = [string(a:text)]
  endif

  let l:prefix = s:types_to_prefixes[a:type]
  let l:term_pfx = s:types_to_term_prefixes[a:type]
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
  call l:self.insertLines(-1, l:to_insert)

  let l:self['__counter'] += 1  " received another message
  if l:self.__shouldWrite()  " based on the current received count,
    call l:self.__write()
  endif
endfunction

" BRIEF:  Send a report, which might be logged by a handler.
" PARAM:  kind  (v:t_string)
" PARAM:  brief (v:t_string)
" PARAM:  long  (v:t_string?)
" PARAM:  alert (v:t_bool?)
" PARAM:  other (any?)
function! dapper#log#DebugLogger#notifyReport(kind, brief, ...) abort dict
  call dapper#log#DebugLogger#CheckType(l:self)
  let l:msg = call('dapper#dap#Report#new', [0, '', a:kind, a:brief] + a:000)
  call dapper#receive(l:msg)
endfunction
