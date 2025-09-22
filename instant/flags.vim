let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

""
" @section Introduction, intro
" This is a plugin for FZF-related utilities and workflows that integrate well
" with both custom workflows and with some prefab FZF workflows.

""
" @section Configuration, config
" @plugin(name) is configured using maktaba flags. It defines a @flag(name) flag
" that can be configured using |Glaive| or a plugin manager that uses the
" maktaba setting API. It also supports entirely disabling commands from being
" defined by clearing the plugin[commands] flag.

""
" The regexes in this flag will limit matching paths for OldFiles to only
" paths that match entries in this list.
"
" An empty list results in no restrictions.
call s:plugin.Flag('path_restrictions', [])

""
" The regexes in this list will prune the remaining files that already matched
" the [path_restrictions] flag.
call s:plugin.Flag('path_filters', ["^/tmp", "^/usr/share/vim"])


""
" If provided, this will be a Funcref that returns a list of additional
" filters to be used.
call s:plugin.Flag('filter_func', 'fpop#VcsRoot')

""
" Additional arguments provided to FZF.
call s:plugin.Flag('fzf_args', ["--reverse", "--cycle"])
