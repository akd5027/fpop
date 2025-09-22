Loading the plugin manually.

  :set nocompatible
  :let g:helloworlddir = fnamemodify($VROOMFILE, ':p:h:h')
  :let g:bootstrapfile = g:helloworlddir . '/bootstrap.vim'
  :execute 'source' g:bootstrapfile

  :call maktaba#LateLoad()
