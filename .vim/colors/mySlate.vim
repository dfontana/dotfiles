:set background=dark
:highlight clear
if version > 580
    hi clear
    if exists("syntax_on")
        syntax reset
    endif
endif
let colors_name = "mySlate"

" ===== Syntax
:hi Todo            cterm=underline     ctermfg=green
:hi Comment         cterm=bold          ctermfg=11
:hi Define                              ctermfg=yellow
:hi Type                                ctermfg=2
:hi Function                            ctermfg=brown
:hi Structure                           ctermfg=green
:hi Include                             ctermfg=red
:hi PreProc                             ctermfg=red
:hi Identifier                          ctermfg=red
:hi Statement                           ctermfg=lightblue
:hi Repeat	        cterm=underline	    ctermfg=White
:hi String                              ctermfg=darkcyan
:hi Constant                            ctermfg=brown
:hi Special                             ctermfg=brown
:hi Operator                            ctermfg=red
:hi Number                              ctermfg=brown

""" Links colorings (May need to remove :'s)
:hi link Character      String
:hi link Float          Number
:hi link Conditional    Repeat
:hi link Boolean	    Constant
:hi link Label		    Statement
:hi link Keyword	    Statement
:hi link Exception	    Statement

:hi link Include	    PreProc
:hi link Define	        PreProc
:hi link Macro		    PreProc
:hi link PreCondit	    PreProc
:hi link StorageClass	Type
:hi link Structure	    Type
:hi link Typedef	    Type
:hi link Tag		    Special
:hi link SpecialChar	Special
:hi link Delimiter	    Special
:hi link SpecialComment Special
:hi link Debug		    Special


" ===== Errors, Editor, and Unknown
:hi VertSplit       cterm=reverse
:hi Folded                              ctermfg=grey        ctermbg=darkgrey
:hi FoldColumn                          ctermfg=4           ctermbg=7
:hi IncSearch       cterm=none          ctermfg=yellow      ctermbg=green
:hi Search          cterm=none          ctermfg=grey        ctermbg=blue
:hi MoreMsg                             ctermfg=darkgreen
:hi Question                            ctermfg=green
:hi SpecialKey                          ctermfg=darkgreen
:hi Title           cterm=bold          ctermfg=yellow
:hi NonText         cterm=bold          ctermfg=blue
:hi Visual          cterm=reverse
:hi StatusLine      cterm=bold,reverse
:hi StatusLineNC    cterm=reverse
:hi ModeMsg         cterm=none          ctermfg=brown
:hi Underlined      cterm=underline     ctermfg=5


:hi LineNr                              ctermfg=3
:hi Ignore          cterm=bold          ctermfg=7
:hi Directory                           ctermfg=darkcyan
:hi VisualNOS       cterm=bold,underline
:hi WildMenu                            ctermfg=0           ctermbg=3
:hi DiffAdd                                                 ctermbg=4
:hi DiffChange                                              ctermbg=5
:hi DiffDelete      cterm=bold          ctermfg=4           ctermbg=6
:hi DiffText        cterm=bold                              ctermbg=1
:hi ErrorMsg        cterm=bold          ctermfg=7           ctermbg=1
:hi Error           cterm=bold          ctermfg=7           ctermbg=1
:hi SpellErrors     cterm=bold          ctermfg=7           ctermbg=1
:hi WarningMsg                          ctermfg=1

