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
    let l:nr = split(g:dapper_log_buffer_writeback, 'every')[1] + 0
    throw '(dapper.nvim) "every" in g:dapper_log_buffer_writeback must be '
        \ . 'followed by a number (given: '.g:dapper_log_buffer_writeback.')'
  elseif index(s:dapper_log_buffer_writeback_values,
        \ g:dapper_log_buffer_writeback) ==# -1
    throw '(dapper.nvim) Value '.g:dapper_log_buffer_writeback.' for '
        \.'g:dapper_log_buffer_writeback not in list: '
        \.string(s:dapper_log_buffer_writeback_values)
  endif
  return g:dapper_log_buffer_writeback
endfunction
