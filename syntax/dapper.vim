scriptencoding utf-8
" Syntax file for dapper.nvim
" Language: dapper
" Maintainer: Yilin Yang

if exists('b:current_syntax')
    finish
endif

let b:current_syntax = 'dapper'

"===============================================================================
hi default link dapperTags NonText

"-------------------------------------------------------------------------------
syn region dapperThreads matchgroup=dapperTags
    \ start=/^<threads>/ end=|^</threads>|
    \ contains=@dapperThreadsElements
    \ concealends keepend

syn match dapperThreadsID /^thread id: / contained
syn match dapperThreadsIDNum /[0-9]\{-}\t/ contained
syn region dapperThreadsName start=/name: / end=/\tstatus:/me=s-1 contained
syn match dapperThreadsStatus /status:.*$/

syn cluster dapperThreadsElements
    \ contains=dapperThreadsID,
             \ dapperThreadsIDNum,
             \ dapperThreadsName,
             \ dapperThreadsStatus

hi default link dapperThreadsID Label
hi default link dapperThreadsIDNum Number
hi default link dapperThreadsName Function
hi default link dapperThreadsStatus Question

"-------------------------------------------------------------------------------
syn region dapperStackTrace matchgroup=dapperTags
    \ start=/^<stacktrace>/ end=|^</stacktrace>|
    \ contains=@dapperStackTraceElements
    \ concealends keepend

syn match dapperSTIndex /^([0-9]\{-})/ contained
syn match dapperSTPresentationHint /\[0-90-9\]/ nextgroup=dapperSTLineAndCol contained
syn region dapperSTLineAndCol start=/(l:/ end=/)/
    \ contains=dapperSTLineNoColNo nextgroup=dapperSTFrameName contained
  syn match dapperSTLineNoColNo /[0-9]/ contained
syn match dapperSTFrameName /[\s]*$/ contained

syn cluster dapperStackTraceElements
    \ contains=dapperSTIndex,
             \ dapperSTPresentationHint,
             \ dapperSTLineAndCol,
             \ dapperSTFrameName

hi default link dapperSTIndex Title
hi default link dapperSTPresentationHint SpecialKey
hi default link dapperSTLineAndCol Statement
hi default link dapperSTLineNoColNo Number
hi default link dapperSTFrameName Function

"-------------------------------------------------------------------------------
syn region dapperVariables matchgroup=dapperTags
    \ start=/^<variables>/ end=|^</variables>|
    \ contains=@dapperVariablesSubregions,@dapperVariablesElements
    \ concealends keepend


syn match dapperVariablesBullet /^\(\s\s\)*\zs[>v-]\ze/ contained

" the header for a particular scope
syn region dapperVariablesScope
    \ start="\(^[>v]\)\@<= " end="$"
    \ contains=@dapperVariableElements,
             \ dapperVariablesScopeName,
             \ dapperVariablesScopeDetails
    \ contained oneline
syn match dapperVariablesScopeName / \zs\S\{-1,}\ze :/
    \ nextgroup=dapperVariablesScopeDetails contained
syn match dapperVariablesScopeDetails / : \zs.*\ze$/ contained

syn region dapperVariablesVariable
    \ start="\(^\(\s\s\)\+[>v-]\)\@<= " end="$"
    \ contains=@dapperVariableElements,
             \ dapperVariablesVariableName,
             \ dapperVariablesVariableHint,
             \ dapperVariablesVariableValue
    \ nextgroup=dapperVariablesVariableName
    \ contained oneline

syn match dapperVariablesVariableName /[^,:]*,/me=e-1
    \ nextgroup=dapperVariablesVariableType contained
syn match dapperVariablesVariableType /, [^,:]*[,:]/hs=s+2,me=e-1
    \ nextgroup=dapperVariablesVariableHint contained
syn match dapperVariablesVariableHint /, [^:]*:/hs=s+2,me=e-1
    \ nextgroup=dapperVariablesVariableValue contained
syn match dapperVariablesVariableValue /: .*$/hs=s+2 contained


syn cluster dapperVariablesElements
    \ contains=dapperVariablesBullet

syn cluster dapperVariablesSubregions
    \ contains=dapperVariablesScope,
             \ dapperVariablesVariable

hi default link dapperVariablesBullet   Statement

hi default link dapperVariablesScopeName    Title
hi default link dapperVariablesScopeDetails Comment

hi default link dapperVariablesVariableName   Identifier
hi default link dapperVariablesVariableType   Type
hi default link dapperVariablesVariableHint   Comment
hi default link dapperVariablesVariableValue  Constant
