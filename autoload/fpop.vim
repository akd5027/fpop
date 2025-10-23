let s:plugin = maktaba#plugin#Get('fpop')

""
" @section Functions
" Functions for fpop

""
" @section Picker Options, picker-options
" @parentsection functions
"
" When invoking the picker, different options are available that manipulate
" the behavior of the picker
"
" - callback (required)
"
" A mandatory callback function that will be invoked with the stdout generated
" by the FZF command.
"
" - fzf_args (optional)
"
" These are additional arguments that will be provided to FZF for this
" specific invocation

""
" Follows the typical callback mandats of job-start, the {channel} arguments
" provides information about the callback channel.  The {message} provides
" information about the callback status.  This is a terminal callback though,
" so we capture output from the command in a buffer and then consume that
" buffer through external capture/coordination.
function! fpop#PickerCallback(channel, message)
  call popup_close(win_getid())

  call term_wait(s:term_buf)

  " Oddly, if your popup terminal is too narrow (i.e. not enough columns in the
  " popup terminal), then the output will get spit to stdout with line wrapping.
  " This means that the output buffer will end up with multiple lines instead of
  " just one for a single selection.  We combat this by enabling `--print0` when
  " invoking fzf, and then we join all lines here and then split them again on
  " the null character.
  let lines = getbufline(s:term_buf, 1, "$")
        \->join('')
        \->split('\x00')

  exec ':bwipeout! ' .. s:fpop_buf
  exec ':bwipeout! ' .. s:term_buf
  unlet s:fpop_buf

  " ViM will return an empty buffer with a single line if no selection was
  " made.  We prune that out to avoid calling the user callback if no
  " selection was made.
  if len(l:lines) == 1 && empty(l:lines[0])
    " Nothing to do if no selection was made.
    return
  endif

  " Set by the @function(fpop#Picker) function prior to this invocation.
  call s:picker_user_callback(lines)
endfunction


""
" @public
" A generic callback that opens the first file referred to by {lines}.
function! fpop#OpenCallback(lines)
  execute 'edit ' .. a:lines[0]
endfunction

""
" @public
" A callback for file version-controlled files.
"
" each entry from FZF is a null-terminated entry.  This callback comes from an
" invocation that uses '--expect' to indicate what action to take with the
" selected content.  This function expects two major elements in the provided
" line, the action, and everything else. The action will indicate how to handle
" the provided file, and then fhe file will be the recipient of that action.
function! fpop#FileCallback(lines)
  let [action ; rest] = split(a:lines[0])
  let file = join(rest, ' ')

  call s:plugin.logger.Debug('File Callback: {' .. l:action .. ', ' .. l:file .. '}')

  if l:action == 'enter'
    execute 'edit ' .. l:file
  elseif l:action == 'ctrl-s'
    execute 'vertical split ' .. l:file
  elseif l:action == 'ctrl-v'
    execute 'edit ' .. l:file
    AKVdiff
  else
    call s:plugin.logger.Error('Unknown file callback action: ' .. l:action)
  endif
endfunction

function! s:PathRestriction(index, value)
  for restriction_value in s:path_restrictions
    if a:value =~# l:restriction_value
      return 1
    endif
  endfor

  return 0
endfunction

function! s:PathFilter(index, value)
  for filter_value in s:path_filters
    if a:value =~# l:filter_value
      return 0
    endif
  endfor

  return 1
endfunction

""
" A filter function that returns the root of the current version control
" system.
function! fpop#VcsRoot()
  let jj_call = maktaba#syscall#Create(['jj', 'root']).Call(0)
  if len(jj_call.stdout)
    call s:plugin.logger.Debug('Adding jj path to root: ' .. trim(jj_call.stdout))
    return [trim('^' .. jj_call.stdout)]
  endif

  let git_call = maktaba#syscall#Create(['git', 'rev-parse', '--show-toplevel']).Call(0)
  if len(git_call.stdout)
    call s:plugin.logger.Debug('Adding git path to root: ' .. trim(git_call.stdout))
    return [trim('^' .. git_call.stdout)]
  endif
  
  return []
endfunction

""
" @public
" A utility method that can be called by custom user workflows or
" fpop-internal workflows alike.  The method requires input {content} as well
" as an optional dictionary of [options].
"
" [options] takes the form of |picker-options|
"
" In the event that the picker output has no output lines, no user callback
" will be invoked.
function! fpop#Picker(content, ...)
  let options = get(a:, 1, #{})

  if empty(a:content)
    call s:plugin.logger.Warn('No entries provided to fpop#Picker.')
    return
  endif

  let s:fpop_buf = bufadd('_fpop')
  call bufload(s:fpop_buf)

  call deletebufline(s:fpop_buf, 1, "$")
  call appendbufline(s:fpop_buf, 1, a:content)
  call deletebufline(s:fpop_buf, 1)

  let s:picker_user_callback = get(l:options, 'callback', function('fpop#OpenCallback'))

  let s:term_buf = term_start(['fzf', '--print0', '--border=double']
        \+ s:plugin.Flag('fzf_args') + get(l:options, 'fzf_args', []),
        \#{
          \exit_cb: 'fpop#PickerCallback',
          \term_name: 'fzf_term',
          \in_io: 'buffer',
          \in_buf: s:fpop_buf,
          \hidden: 1,
      \})

  let l:winwidth = float2nr(&columns * 0.8)
  let l:winheight = float2nr(&lines * 0.8)

  let winid = popup_create(s:term_buf, #{
        \minwidth: l:winwidth,
        \minheight: l:winheight,
      \})
endfunction

""
" @public
" A specialized version of |Picker| that specifically handles a single file
" with options for splitting, diffing, etc.
function! fpop#FilePicker(files)
  call fpop#Picker(a:files, #{
        \fzf_args: ['--expect=enter,ctrl-s,ctrl-v', '--header=Open (enter) | Split (^s) | VDiff (^v)'],
        \callback: function('fpop#FileCallback')
        \})

endfunction


""
" @public
" Allows the current visible buffers to be selected with FZF.
function! fpop#Buffers()
  let buffers = getbufinfo()
        \->filter('v:val["listed"] && len(v:val["name"])')
        \->map('join([v:val["bufnr"], v:val["name"]], " ")')

  " Ignore the popup if there are no named buffers to select.
  if empty(l:buffers)
    return
  endif

  call fpop#Picker(
      \l:buffers,
      \#{fzf_args: ['--nth=2', '--accept-nth=2']}
    \)
endfunction

""
" @public
" The allows the last previous 100 open files within vim to be selected.
"
" This method will filter out files matching 'tmp' before sharing the methods
" with the provided callback.
function! fpop#OldFiles()
  let path_values = copy(v:oldfiles)->map('substitute(v:val, "\\~", $HOME, "")')

  let func = s:plugin.Flag('filter_func')

  " Staging these values for list filtering callbacks to consume.
  let s:path_restrictions = copy(s:plugin.Flag('path_restrictions'))
  let s:path_filters = copy(s:plugin.Flag('path_filters'))

  if len(l:func)
    let s:path_restrictions += call(l:func, [])
  endif

  call s:plugin.logger.Debug('Starting path values: ' .. string(l:path_values))
  call s:plugin.logger.Debug('Restrictions: ' .. string(s:path_restrictions))
  call s:plugin.logger.Debug('Filters: ' .. string(s:path_filters))

  if len(s:path_restrictions)
    call filter(l:path_values, function('s:PathRestriction'))
  endif
  call filter(l:path_values, function('s:PathFilter'))

  unlet s:path_restrictions
  unlet s:path_filters

  call fpop#Picker(
      \l:path_values,
      \#{
        \fzf_args: ["--preview=bash -c 'cat {}'", "--preview-window=bottom"],
        \callback: function('fpop#OpenCallback')
      \}
    \)
endfunction

