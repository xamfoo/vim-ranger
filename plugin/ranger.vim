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

function! RangerOpenIn(path, prevBuffer, Callback)
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
    let l:currentBuffer = bufnr('%')
    let l:hasFilesToOpen = filereadable(g:ranger_tmp_file_path)

    if filereadable(g:ranger_tmp_dir_path)
      let l:targetDir = readfile(g:ranger_tmp_dir_path)
      call delete(g:ranger_tmp_dir_path)
      call s:onChangeDirectory(targetDir)
    endif

    if hasFilesToOpen
      let l:filesToOpen = readfile(g:ranger_tmp_file_path)
      call delete(g:ranger_tmp_file_path)
      call a:Callback(filesToOpen)
      exec 'bd! ' . l:currentBuffer
      return 0
    endif

    if a:prevBuffer == currentBuffer
      enew
      exec 'bd! ' . l:currentBuffer
      return 0
    endif

    if bufexists(a:prevBuffer)
      exec 'buffer ' . a:prevBuffer
    else
      enew
    endif

    exec 'bd! ' . l:currentBuffer
  endfunction

  function! s:OnExitDeferred(...)
    call timer_start(0, function('s:OnExit'))
  endfunction

  if has("nvim")
    enew
    call termopen(l:term_command, { 'on_exit': function('s:OnExitDeferred') })
    setlocal nonumber norelativenumber
    set bufhidden=unload

    if mode() == 'n'
      :startinsert
    endif
  else
    call term_start(l:term_command, { 'curwin': 1, 'close_cb': function('s:OnExitDeferred') })
  endif
endfunction

function! RangerPickFile()
  let l:currentBuffer = bufnr('%')

  if empty(expand('%'))
    return RangerOpenIn('%:p:h', currentBuffer, function('s:openFiles'))
  else
    return RangerOpenIn('%:p', currentBuffer, function('s:openFiles'))
  endif
endfunction

" vim:set sw=2 sts=2:
