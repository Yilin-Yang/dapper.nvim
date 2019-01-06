function! s:VimLTypeToString(type) abort
  let l:type = a:type + 0  " cast to number
  let l:types = {
      \ 0: 'v:t_number',
      \ 1: 'v:t_string',
      \ 2: 'v:t_func',
      \ 3: 'v:t_list',
      \ 4: 'v:t_dict',
      \ 5: 'v:t_float',
      \ 6: 'v:t_bool',
      \ 7: 'v:null',
      \ }
  if !has_key(l:types, l:type)
    throw '(dapper.nvim) Nonexistent variable type with val: ' . a:type
  endif
  return l:types[a:type]
endfunction

function! s:AssertType(variable, expected, variable_name) abort
    if type(a:variable) !=# a:expected
        throw '(dapper.nvim) Variable ' . a:variable_name
            \ . ' should have type: ' . s:VimLTypeToString(a:expected)
            \ . ' but instead has type: ' . s:VimLTypeToString(type(a:variable))
    endif
endfunction

"===============================================================================

" RETURNS:  (v:t_dict)  Mapping between a filetype and all debug adapter
"                       configurations for that filetype.
function! dapper#settings#FiletypesToConfigs() abort
  if !exists('g:dapper_filetypes_to_configs')
    let g:dapper_filetypes_to_configs = {}
  endif
  call s:AssertType(
      \ g:dapper_filetypes_to_configs,
      \ v:t_dict,
      \ 'g:dapper_filetypes_to_configs'
      \ )
  return g:dapper_filetypes_to_configs
endfunction

" RETURNS:  (v:t_string)  Keymapping used to 'dig down' to a deeper level of a
"                         'RabbitHole' buffer, e.g. to go from a `ThreadBuffer`
"                         down to the selected `StackTraceBuffer`.
function! dapper#settings#DigDownMapping() abort
  if !exists('g:dapper_dig_down_mapping')
    let g:dapper_dig_down_mapping = '<cr>'
  endif
  call s:AssertType(
      \ g:dapper_dig_down_mapping,
      \ v:t_string,
      \ 'g:dapper_dig_down_mapping'
      \ )
  return g:dapper_dig_down_mapping
endfunction

" RETURNS:  (v:t_string)  Keymapping used to 'climb up' to a higher level of a
"                         'RabbitHole' buffer, e.g. to go from a
"                         `StackTraceBuffer` up to the parent 'ThreadBuffer'.
function! dapper#settings#ClimbUpMapping() abort
  if !exists('g:dapper_climb_up_mapping')
    let g:dapper_climb_up_mapping = '<Esc>'
  endif
  call s:AssertType(
      \ g:dapper_climb_up_mapping,
      \ v:t_string,
      \ 'g:dapper_climb_up_mapping'
      \ )
  return g:dapper_climb_up_mapping
endfunction

" RETURNS:  (v:t_string)  Keymapping used to toggle breakpoints on a line.
function! dapper#settings#ToggleBreakpointMapping() abort
  if !exists('g:dapper_toggle_breakpoint_mapping')
    let g:dapper_toggle_breakpoint_mapping = '<leader>b'
  endif
  call s:AssertType(
      \ g:dapper_toggle_breakpoint_mapping,
      \ v:t_string,
      \ 'g:dapper_toggle_breakpoint_mapping'
      \ )
  return g:dapper_toggle_breakpoint_mapping
endfunction


" RETURNS:  (v:t_string)  The `bufname` of the debug log buffer. Used only
"                         when the log buffer is not being written to a file.
function! dapper#settings#LogBufferName() abort
  if !exists('g:dapper_log_buffer_name')
    let g:dapper_log_buffer_name = '[dapper] Debug Log'
  endif
  call s:AssertType(
      \ g:dapper_log_buffer_name,
      \ v:t_string,
      \ 'g:dapper_log_buffer_name'
      \ )
  return g:dapper_log_buffer_name
endfunction

" RETURNS:  (v:t_string)  The output file to which the debug log would be
"                         written, if configured to do so.
function! dapper#settings#Logfile() abort
  if !exists('g:dapper_logfile')
    let g:dapper_logfile = $HOME.'/dapper_debug_log.vim.dp'
  endif
  call s:AssertType(
      \ g:dapper_logfile,
      \ v:t_string,
      \ 'g:dapper_logfile'
      \ )
  return g:dapper_logfile
endfunction

" RETURNS:  (v:t_string)  Whether or not to write the debug log buffer out to
"                         a file.
let s:dapper_log_buffer_writeback_values = [
    \ 'never', 'onclose', 'every[N_MSGS]', 'always'
    \ ]
function! dapper#settings#LogBufferWriteback() abort
  if !exists('g:dapper_log_buffer_writeback')
    let g:dapper_log_buffer_writeback = 'never'
  endif
  call s:AssertType(
      \ g:dapper_log_buffer_writeback,
      \ v:t_string,
      \ 'g:dapper_log_buffer_writeback'
      \ )
  if g:dapper_log_buffer_writeback[0:4] ==# 'every'
    let l:nr = split(g:dapper_log_buffer_writeback, 'every')[0] + 0
    if !l:nr
      throw '(dapper.nvim) "every" in g:dapper_log_buffer_writeback must be '
          \ . 'followed by a number (given: '.g:dapper_log_buffer_writeback.')'
    endif
  elseif index(s:dapper_log_buffer_writeback_values,
        \ g:dapper_log_buffer_writeback) ==# -1
    throw '(dapper.nvim) Value '.g:dapper_log_buffer_writeback.' for '
        \.'g:dapper_log_buffer_writeback not in list: '
        \.string(s:dapper_log_buffer_writeback_values)
  endif
  return g:dapper_log_buffer_writeback
endfunction

" RETURNS:  (v:t_string)  What kinds of messages dapper should echo to the
"     user at the commandline.
let s:dapper_echo_messages_values = [
    \ 'never', 'only_errors', 'all_errors', 'statuses', 'all_statuses'
    \ ]
function! dapper#settings#EchoMessages() abort
  if !exists('g:dapper_echo_messages')
    let g:dapper_echo_messages = 'only_errors'
  endif
  call s:AssertType(
      \ g:dapper_echo_messages,
      \ v:t_string,
      \ 'g:dapper_echo_messages'
      \ )
  if index(s:dapper_echo_messages_values,
        \ g:dapper_echo_messages) ==# -1
    throw '(dapper.nvim) Value '.g:dapper_echo_messages.' for '
        \.'g:dapper_echo_messages not in list: '
        \.string(s:dapper_echo_messages_values)
  endif
  return g:dapper_echo_messages
endfunction

" RETURNS:  (v:t_string)  How much information to print when echoing a message.
let s:dapper_echo_message_verbosity_values = [
    \ 'kind', 'brief', 'long', 'everything'
    \ ]
function! dapper#settings#EchoMessageVerbosity() abort
  if !exists('g:dapper_echo_message_verbosity')
    let g:dapper_echo_message_verbosity = 'brief'
  endif
  call s:AssertType(
      \ g:dapper_echo_message_verbosity,
      \ v:t_string,
      \ 'g:dapper_echo_message_verbosity'
      \ )
  if index(s:dapper_echo_message_verbosity_values,
        \ g:dapper_echo_message_verbosity) ==# -1
    throw '(dapper.nvim) Value '.g:dapper_echo_message_verbosity.' for '
        \.'g:dapper_echo_message_verbosity not in list: '
        \.string(s:dapper_echo_message_verbosity_values)
  endif
  return g:dapper_echo_message_verbosity
endfunction

" RETURNS:  (v:t_bool)  Whether a ReportHandler should invoke `:redraw` before
"                       echoing a message. In practice, this lets 'later'
"                       ReportHandler instances clobber the messages echoed by
"                       'earlier' ReportHandler instances, which may be
"                       helpful for reducing `hit-enter` prompts.
function! dapper#settings#RedrawOnEcho() abort
  if !exists('g:dapper_redraw_on_echo')
    let g:dapper_redraw_on_echo = v:false
  endif
  call s:AssertType(
      \ g:dapper_redraw_on_echo,
      \ v:t_bool,
      \ 'g:dapper_redraw_on_echo'
      \ )
  return g:dapper_redraw_on_echo
endfunction
