function! dapper#log#DebugLogger#get() abort
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
  let l:new = dapper#Buffer#new(l:bufset)
  let l:new['TYPE']['DebugLogger'] = 1
  let l:new['__writeback'] = l:writeback
  let l:new['__settings'] = l:bufset
  let l:new['__counter'] = 0
  let l:new['__last_line_written'] = 0
  let l:new['__shouldWrite'] =
      \ function('dapper#log#DebugLogger#__shouldWrite', l:new)
  let l:new['__write'] = function('dapper#log#DebugLogger#__write', l:new)
  let l:new['__onExit'] = function('dapper#log#DebugLogger#__onExit', l:new)
  let l:new['log'] = function('dapper#log#DebugLogger#log', l:new)

  let g:dapper_debug_logger = l:new

  augroup dapper_debug_logger
    au!
    autocmd VimLeave * call g:dapper_debug_logger.__onExit()
  augroup end

  return g:dapper_debug_logger
endfunction

let s:writeback_to_bufsettings = {
    \ 'never': {
        \ 'fname': dapper#settings#LogBufferName(),
        \ 'bufhidden': 'hide',
        \ 'buflisted': v:false,
        \ 'buftype' : 'nofile',
        \ 'swapfile': v:false,
        \ },
    \ 'onclose': {
        \ 'fname': dapper#settings#LogBufferWriteback(),
        \ 'bufhidden': 'hide',
        \ 'buflisted': v:false,
        \ 'buftype' : '',
        \ 'swapfile': v:false,
        \ },
    \ 'every': {
        \ 'fname': dapper#settings#LogBufferWriteback(),
        \ 'bufhidden': 'hide',
        \ 'buflisted': v:false,
        \ 'buftype' : '',
        \ 'swapfile': v:true,
        \ 'interval': -1,
        \ },
    \ 'always': {
        \ 'fname': dapper#settings#LogBufferWriteback(),
        \ 'bufhidden': 'hide',
        \ 'buflisted': v:false,
        \ 'buftype' : '',
        \ 'swapfile': v:true,
      \ }
    \ }

function! dapper#log#DebugLogger#CheckType(object) abort
  if type(a:object) !=# v:t_dict || !has_key(a:object, 'TYPE') || !has_key(a:object['TYPE'], 'DebugLogger')
  try
    let l:err = '(dapper#log#DebugLogger) Object is not of type DebugLogger: '.string(a:object)
  catch
    redir => l:object
    echo a:object
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
  " append to file asynchronously
  call writefile(l:to_writeback, l:fname, 'aS')
  let l:self['__counter'] += 1
endfunction

" BRIEF:  Perform last-minute cleanup, execute writebacks before closing vim.
function! dapper#log#DebugLogger#__onExit() abort dict
  call dapper#log#DebugLogger#CheckType(l:self)
  if l:self['writeback'] ==# 'onclose' || l:self['writeback'] ==# 'always'
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
    \ 'normal': '[NORMAL]',
    \ }
let s:types_to_term_prefixes = {
    \ 'error':  '[/E]',
    \ 'normal': '[/N]',
    \ }
function! dapper#log#DebugLogger#log(text, ...) abort dict
  call dapper#log#DebugLogger#CheckType(l:self)
  let a:type = get(a:000, 0, 'normal')
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
    if has('*strftime') | let l:ts = strftime('%c')
    else                | throw ''
    endif
  catch
    let l:ts = localtime()
  endtry

  let l:to_insert = [l:ts.': '.l:prefix] + l:to_insert
  let l:i = 1 | while l:i < len(l:to_insert)
    let l:to_insert[l:i] = "\t".l:to_insert[l:i]
  let l:i += 1 | endwhile
  let l:to_insert += [l:term_pfx]
  call l:self.insertLines(-1, l:to_insert)

  if l:self.__shouldWrite()
    call l:self.__write()
  endif
endfunction
