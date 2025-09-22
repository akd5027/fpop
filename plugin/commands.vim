""
" @section Commands
"
" fpop-provided commands that be used in custom mappings or invoked directly.
" Commands provide 
let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

""
" Provides insight into recently opened files by vim.  This is effectively an
" fzf-equivalent to ViM's built-in |:oldfiles| command.
"
" Flags can be provided that attempt to limit the parsed flags to the current
" VCS/SCM pathing.
command OldFiles call fpop#OldFiles()

""
" Provides fzf selection of currently loaded buffers.  Only listed buffers are
" shown.
command Buffers call fpop#Buffers()
