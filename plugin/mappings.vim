let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

let s:prefix = s:plugin.MapPrefix('f')

""
" Shows the recent 100 files opened by vim for fuzzy selection.
execute 'nnoremap <unique> <silent>' s:prefix . 'o' ':OldFiles<CR>'
