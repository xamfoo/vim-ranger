" vim-ranger - vim integration with ranger
" Maintainer:   Max Foo
" Version:      0.1

if exists("g:ranger_loaded") || &cp || v:version < 700
  finish
endif
let g:ranger_loaded = 1

if !exists('g:ranger_command')
  let g:ranger_command = 'ranger'
endif

if !exists('g:ranger_buffer_close_command')
  let g:ranger_buffer_close_command = 'bd'
endif

if !exists('g:ranger_tmp_file_path')
  let g:ranger_tmp_file_path = '/tmp/vim_ranger_chosenfiles'
endif

if !exists('g:ranger_tmp_dir_path')
  let g:ranger_tmp_dir_path = '/tmp/vim_ranger_chosendir'
endif

function! s:openFiles(files)
  for f in a:files
    exec 'edit ' . fnameescape(f)
  endfor

  " redraw!
  " " reset the filetype to fix the issue that happens
  " " when opening ranger on VimEnter (with `vim .`)
  " filetype detect

  " " Hit Esc to clear any error bell
  " call feedkeys("\<Esc>")
endfunction

function! s:onChangeDirectory(directory_list)
  let l:directory = get(a:directory_list, 0, '')

  if isdirectory(l:directory)
    execute 'cd ' . fnameescape(l:directory)
  endif
endfunction

function! RangerOpenIn(path, Callback)
  let currentPath = expand(a:path)

  if isdirectory(currentPath)
    let l:term_command = g:ranger_command
          \. ' --choosefiles=' . g:ranger_tmp_file_path
          \. ' "' . currentPath . '"'
  else
    let l:term_command = g:ranger_command
          \. ' --choosefiles=' . g:ranger_tmp_file_path
          \. ' --selectfile="' . currentPath . '"'
  endif

  function! s:OnExit(...) closure
    " execute g:ranger_buffer_close_command

    if filereadable(g:ranger_tmp_file_path)
      call a:Callback(readfile(g:ranger_tmp_file_path))
    endif

    if filereadable(g:ranger_tmp_dir_path)
      call s:onChangeDirectory(readfile(g:ranger_tmp_dir_path))
    endif

    call delete(g:ranger_tmp_file_path)
    call delete(g:ranger_tmp_dir_path)
  endfunction

  function! s:OnExitDeferred(...)
    call timer_start(0, function('s:OnExit'))
  endfunction

  call term_start(l:term_command, { 'curwin': 1, 'close_cb': function('s:OnExitDeferred') })
endfunction

function! RangerPickFile()
  if empty(expand('%'))
    return RangerOpenIn('%:p:h', function('s:openFiles'))
  else
    return RangerOpenIn('%:p', function('s:openFiles'))
  endif
endfunction

" vim:set sw=2 sts=2: