let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

""
" @section Configuration, config
" dapper.nvim may be configured in three ways: by using Google's Glaive plugin;
" by setting dapper.nvim's maktaba flags; or by using "legacy" global
" variables (i.e. by explicitly setting variables like
" `g:dapper_dig_down_mapping` in your vimrc).
"
" The former two are strongly recommended: legacy configuration will work for
" "static" configuration, but generally won't be able to change dapper.nvim's
" behavior at runtime.
"
" Install Glaive (https://github.com/google/glaive) and use the |:Glaive|
" command to configure dapper.nvim's maktaba flags. Alternatively, one can
" put the following in their .vimrc:
" >
"   " retrieve dapper.nvim's plugin handle
"   let g:dapper_nvim = maktaba#plugin#Get('dapper.nvim')
"
"   " to set dapper.nvim:dig_down_mapping to '<leader>d'
"   call g:dapper_nvim.Flag('dig_down_mapping', '<leader>d')
"
"   " to disable all logging entirely
"   call g:dapper_nvim.Flag('min_log_level', 'no_logging')
" <

""
" @public
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

function! s:EnsureHoldsOnlyStrings(List) abort
  call typevim#ensure#IsList(a:List)
  for l:Item in a:List
    call maktaba#ensure#IsString(l:Item)
  endfor
  return a:List
endfunction

function! s:StrListToDict(List) abort
  call typevim#ensure#IsList(a:List)
  let l:to_return = {}
  for l:Item in a:List
    let l:to_return[maktaba#ensure#IsString(l:Item)] = 1
  endfor
  return l:to_return
endfunction

function! s:EnsureNoSharedKeys(ref_dictname, errmsg_fmt, ToCheck) abort
  call typevim#ensure#IsDict(a:ToCheck)
  let l:reference = typevim#ensure#IsDict(s:plugin.Flag(a:ref_dictname))
  for l:key in keys(a:ToCheck)
    if !has_key(l:reference, l:key) | continue | endif
    throw maktaba#error#BadValue(a:errmsg_fmt, l:key)
  endfor
  return a:ToCheck
endfunction

"""""""""""""""""""""""""""""""""""MAPPINGS"""""""""""""""""""""""""""""""""""""

""
" Keymapping used to "dig down" to a deeper level of a dapper.nvim buffer,
" e.g. to go from a "ThreadBuffer" down to the selected "StackTraceBuffer".
call s:plugin.Flag('dig_down_mapping',
    \ s:GlobalSettingOrDefault('g:dapper_dig_down_mapping', '<cr>'))

""
" Keymapping used to "climb up" to a higher level of a dapper.nvim buffer,
" e.g. to go from a "StackTraceBuffer" up to a "ThreadBuffer".
call s:plugin.Flag('climb_up_mapping',
    \ s:GlobalSettingOrDefault('g:dapper_climb_up_mapping', '<Esc>'))

""
" Keymapping used to expand the contents of a collapsed scope or "structured"
" variable (e.g. a class instance, a struct, a list) in a @dict(VariablesBuffer).
call s:plugin.Flag('expand_mapping',
    \ s:GlobalSettingOrDefault(
        \ 'g:dapper_expand_mappping', s:plugin.Flag('dig_down_mapping')))

""
" Keymapping used to collapse the contents of an expanded scope or
" "structured" variable in a @dict(VariablesBuffer).
call s:plugin.Flag('collapse_mapping',
    \ s:GlobalSettingOrDefault(
        \ 'g:dapper_collapse_mapping', '<BS>'))

""
" Keymapping used to toggle breakpoints on the current line. Defaults to "<F9>".
call s:plugin.Flag('toggle_breakpoint_mapping',
    \ s:GlobalSettingOrDefault('g:dapper_toggle_breakpoint_mapping', '<F9>'))

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
" May be set to, in order from lowest to highest severity:
" "debug", "info", "warn", "error", "severe", "no_logging"
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

""
" When retrieving the contents of a structured variable, dapper.nvim can try
" to automatically and recursively retrieve and cache the contents of its
" children, so that expanding one of those variables can occur nearly
" instantly. This option controls the greatest recursion depth to which
" dapper.nvim will perform this inspection. Should be non-negative.
"
" This setting exists to prevent infinite recursion, e.g. if a local variable
" in the debuggee process is infinitely self-recursive, dapper.nvim will stop
" "drilling down" into its contents after delving this many levels deep. It is
" still possible to drill deeper by manually expanding the variable contents
" in the @dict(VariablesBuffer).
"
" However, this recursive retrieval blocks vim. If a stack frame has many
" (hundreds or more) elements, then inspecting its variables would freeze vim
" for up to several minutes. Consequently, this value should never be greater
" than zero unless you plan to use it for performance benchmarking.
call s:plugin.Flag('max_drilldown_recursion',
    \ s:GlobalSettingOrDefault('g:dapper_max_drilldown_recursion', 0))

call s:plugin.flags.max_drilldown_recursion.AddTranslator(
    \ function('typevim#ensure#IsNonNegative'))

""
" The initial depth to which scopes and structured variables will be expanded
" when viewing scopes and variables accessible in a stack frame. Should be a
" non-negative number.
"
" Note that setting this to zero essentially disables on-entry scope
" expansion (since any scopes to be expanded will only "expand" to depth 0),
" overriding settings like @flag(scopes_to_always_expand).
"
" See @flag(menu_expand_depth_on_map) for more details.
call s:plugin.Flag('menu_expand_depth_initial',
    \ s:GlobalSettingOrDefault('g:dapper_menu_expand_depth_initial', 1))

call s:plugin.flags.menu_expand_depth_initial.AddTranslator(
    \ function('typevim#ensure#IsNonNegative'))

""
" The depth to which collapsed variables and scopes will expand when
" triggering @flag(expand_mapping).
"
" When equal to 1, only the immediate children of the selected scope or
" structured variable will be shown; when equal to 2, those children and their
" own children will be shown. Should be a positive number.

call s:plugin.Flag('menu_expand_depth_on_map',
    \ s:GlobalSettingOrDefault('g:dapper_menu_expand_depth_on_map', 1))

call s:plugin.flags.menu_expand_depth_on_map.AddTranslator(
    \ function('typevim#ensure#IsPositive'))

""
" The preferred order in which to display scopes inside of a
" @dict(VariablesBuffer). If a scope comes earlier in this list than another,
" then it will be shown closer to the top of the buffer.
"
" Matching is done by case-sensitive string comparison. Scopes whose names
" don't appear in this list will appear at the end of the buffer sorted in
" alphabetical order.
call s:plugin.Flag('preferred_scope_order',
    \ s:GlobalSettingOrDefault('g:dapper_preferred_scope_order',
        \ ['Local', 'Global']))

call s:plugin.flags.preferred_scope_order.AddTranslator(
    \ function('s:EnsureHoldsOnlyStrings'))

""
" Whether to expand all scopes by default when inspecting a stack frame.
call s:plugin.Flag('expand_scopes_by_default',
    \ s:GlobalSettingOrDefault('g:dapper_expand_scopes_by_default', 1))

call s:plugin.flags.expand_scopes_by_default.AddTranslator(
    \ function('typevim#ensure#IsBool'))

""
" Names of scopes that will always be expanded, overriding
" @flag(expand_scopes_by_default). Scopes that appear in this list cannot
" appear in @flag(scopes_to_never_expand).
call s:plugin.Flag('scopes_to_always_expand',
    \ s:GlobalSettingOrDefault('g:dapper_scopes_to_always_expand', []))
""
" Names of scopes that will never be expanded, overriding
" @flag(expand_scopes_by_default). Scopes that appear in this list cannot
" appear in @flag(scopes_to_always_expand).
call s:plugin.Flag('scopes_to_never_expand',
    \ s:GlobalSettingOrDefault('g:dapper_scopes_to_never_expand', []))

" since these translators each reference the other flag, they need to be
" declared after both flags have been declared
call s:plugin.flags.scopes_to_always_expand.AddTranslator(
    \ function('s:StrListToDict'))
call s:plugin.flags.scopes_to_never_expand.AddTranslator(
    \ function('s:StrListToDict'))

" need to convert both to dicts before retrieving them in these translators
call s:plugin.flags.scopes_to_always_expand.AddTranslator(
    \ function('s:EnsureNoSharedKeys', [
        \ 'scopes_to_never_expand',
        \ 'Cannot add scopename already present in '
            \ . 'scopes_to_never_expand: %s']))
call s:plugin.flags.scopes_to_never_expand.AddTranslator(
    \ function('s:EnsureNoSharedKeys', [
        \ 'scopes_to_always_expand',
        \ 'Cannot add scopename already present in '
            \ . 'scopes_to_always_expand: %s']))

""
" Debug adapters can report that a particular scope is "expensive to
" retrieve," meaning that it has many variables and that trying to display its
" contents may be unacceptably slow. Set this to 1 to avoid expanding these
" scopes by default. If set, overrides @flag(scopes_to_always_expand) and
" @flag(expand_scopes_by_default).
call s:plugin.Flag('dont_expand_expensive_scopes',
    \ s:GlobalSettingOrDefault('g:dapper_dont_expand_expensive_scopes', 0))

call s:plugin.flags.dont_expand_expensive_scopes.AddTranslator(
    \ function('typevim#ensure#IsBool'))
