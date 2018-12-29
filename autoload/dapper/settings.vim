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
