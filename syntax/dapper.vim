scriptencoding utf-8
" Syntax file for dapper.nvim
" Language: dapper
" Maintainer: Yilin Yang

if exists('b:current_syntax')
    finish
endif

"===============================================================================
hi default link dapperTags Comment

"-------------------------------------------------------------------------------
syn region dapperThreads matchgroup=dapperTags
    \ start=/^<threads>/ end=|^</threads>|
    \ contains=@dapperThreadsElements
    \ concealends

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
    \ concealends

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