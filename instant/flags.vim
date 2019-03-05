let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

""
" Return the value of {setting_name}, a scoped variable (e.g.
" `"g:dapper_foobar"`, including the leading `"g:"`), or {default}, if
" {setting_name} has no value set.
"
" This function exists so that dapper.nvim may present a familiar, "legacy"
" interface for plugin settings to the end user, should they decide not to use
" glaive.
"
" @default type_reference=v:null
" @throws WrongType if the variable that {setting_name} represents does not have the same type as {default}.
" @throws Failure if {setting_name} is malformed.
function! s:GlobalSettingOrDefault(setting_name, default)
  call maktaba#ensure#IsString(a:setting_name)
  if exists(a:setting_name)
    execute 'let l:set_val = '.a:setting_name
  else
    let l:set_val = a:default
  endif
  try
    call maktaba#ensure#TypeMatches(l:set_val, a:default)
  catch /ERROR(WrongType)/
    throw maktaba#error#WrongType(
        \ 'Given setting %s has the wrong type! (val: %s)',
        \ a:setting_name, l:set_val)
  endtry
  return l:set_val
endfunction

"""""""""""""""""""""""""""""""""""MAPPINGS"""""""""""""""""""""""""""""""""""""

" Keymapping used to "dig down" to a deeper level of a dapper.nvim buffer,
" e.g. to go from a "ThreadBuffer" down to the selected "StackTraceBuffer".
" Defaults to `"<cr>"`.
call s:plugin.Flag('dig_down_mapping',
    \ s:GlobalSettingOrDefault('g:dapper_dig_down_mapping', '<cr>'))

" Keymapping used to "climb up" to a higher level of a dapper.nvim buffer,
" e.g. to go from a "StackTraceBuffer" up to a "ThreadBuffer". Defaults to
" `"<Esc>"`.
call s:plugin.Flag('climb_up_mapping',
    \ s:GlobalSettingOrDefault('g:dapper_climb_up_mapping', '<Esc>'))

" Keymapping used to toggle breakpoints on the current line. Defaults to "<F9>".
call s:plugin.Flag('toggle_breakpoint_mapping',
    \ s:GlobalSettingOrDefault('g:toggle_breakpoint_mapping', '<F9>'))

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""
" Mapping between a filetype and all debug adapter configurations for that
" filetype.
call s:plugin.Flag('filetypes_to_configs',
    \ s:GlobalSettingOrDefault('g:dapper_filetypes_to_configs', {}))

""
" The |bufname| of the debug log buffer.
call s:plugin.Flag('log_buffer_name',
    \ s:GlobalSettingOrDefault('g:dapper_log_buffer_name', '[dapper] Debug Log'))

""
" The output file to which the debug log will be written, if log writing is
" enabled.
call s:plugin.Flag('logfile',
    \ s:GlobalSettingOrDefault('g:dapper_logfile', $HOME.'/dapper_debug_log.vim.dp'))

""
" Whether or not to write the debug log buffer out to a file on exit.
call s:plugin.Flag('log_buffer_writeback',
    \ s:GlobalSettingOrDefault('g:dapper_log_buffer_writeback', 0))

""
" The "lowest" notification level to be written to the debug log buffer.
" Messages below this level are ignored, while messages at this level or
" higher are printed in their entirety to dapper.nvim's log. This does
" not affect log output to maktaba.
"
" May be set to, in order from lowest to highest severity,
" - "debug"
" - "info"
" - "warn"
" - "error"
" - "severe"
" - "no_logging"
"
" Setting this to "no_logging" disables dapper.nvim's debug logging.
"
" Note that setting this to "low" values, particularly "debug", may incur a
" significant performance penalty, as dapper.nvim's debug log output is
" extremely verbose. It's recommended to set this no lower than "warn" in
" ordinary use.
call s:plugin.Flag('min_log_level',
    \ s:GlobalSettingOrDefault('g:dapper_min_log_level', 'error'))

call s:plugin.flags.min_log_level.AddTranslator(
    \ function('dapper#ensure#IsValidLogLevel'))
