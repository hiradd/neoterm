" Internal: Creates a new neoterm buffer.
function! neoterm#new(...)
  let l:handlers = len(a:000) ? a:1 : {}
  call neoterm#window#create(l:handlers, '')
endfunction

function! neoterm#tnew()
  call neoterm#window#create({}, 'tnew')
endfunction

function! neoterm#toggle()
  " call s:toggle(g:neoterm.last())
  let l:terms = neoterm#get_current_tab_term_all()
  for l:instance in l:terms
    echo l:instance
    call s:toggle(l:instance)
  endfor
endfunction

function! neoterm#toggleAll()
  for l:instance in values(g:neoterm.instances)
    call s:toggle(l:instance)
  endfor
endfunction

function! s:toggle(instance)
  if g:neoterm.has_any()
    let a:instance.origin = exists('*win_getid') ? win_getid() : 0

    if neoterm#term_exists(a:instance)
      call a:instance.close()
    else
      call a:instance.open()
    end
  else
    call neoterm#new()
  end
endfunction

" Internal: Creates a new neoterm buffer, or opens if it already exists.
function! neoterm#open()
  if !neoterm#tab_has_neoterm()
    if !neoterm#current_tab_has_term()
      call neoterm#new()
    else
      call neoterm#get_current_tab_term().open()
    end
  end
endfunction

function! neoterm#close(...)
  let l:instance = g:neoterm.last()
  let l:instance.origin = exists('*win_getid') ? win_getid() : 0

  let l:force = get(a:, '1', 0)
  if g:neoterm.has_any()
    call l:instance.close(l:force)
  end
endfunction

function! neoterm#closeAll(...)
  let l:origin = exists('*win_getid') ? win_getid() : 0

  let l:force = get(a:, '1', 0)
  for l:instance in values(g:neoterm.instances)
    let l:instance.origin = l:origin
    call l:instance.close(l:force)
  endfor
endfunction

" Public: Executes a command on terminal.
" Evaluates any "%" inside the command to the full path of the current file.
function! neoterm#do(command)
  let l:command = neoterm#expand_cmd(a:command)
  call neoterm#exec([l:command, g:neoterm_eof])
endfunction

" Internal: Loads a terminal, if it is not loaded, and execute a list of
" commands.
function! neoterm#exec(command)
  " if !g:neoterm.has_any() || g:neoterm_open_in_all_tabs
  if !neoterm#current_tab_has_term()
    call neoterm#open()
  end

  let l:target_term = neoterm#get_current_tab_term()
  call l:target_term.exec(a:command)
endfunction

function! neoterm#map_for(command)
  exec 'nnoremap <silent> '
        \ . g:neoterm_automap_keys .
        \ ' :T ' . neoterm#expand_cmd(a:command) . '<cr>'
endfunction

" Internal: Expands "%" in commands to current file full path.
function! neoterm#expand_cmd(command)
  let l:command = substitute(a:command, '%\(:[phtre]\)\+', '\=expand(submatch(0))', 'g')

  if g:neoterm_use_relative_path
    let l:path = expand('%')
  else
    let l:path = expand('%:p')
  end

  return substitute(l:command, '%', l:path, 'g')
endfunction

" Internal: Open a new split with the current neoterm buffer if there is one.
"
" Returns: 1 if a neoterm split is opened, 0 otherwise.
function! neoterm#tab_has_neoterm()
  if g:neoterm.has_any()
    let l:buffer_id = g:neoterm.last().buffer_id
    return bufexists(l:buffer_id) > 0 && bufwinnr(l:buffer_id) != -1
  end
endfunction

" Internal: Clear the current neoterm buffer. (Send a <C-l>)
function! neoterm#clear()
  silent call g:neoterm.last().clear()
endfunction

" Only executes if the window is opened.
function! neoterm#normal(cmd)
  silent call g:neoterm.last().normal(a:cmd)
endfunction

" Only executes if the window is opened.
function! neoterm#vim_exec(cmd)
  silent call g:neoterm.last().vim_exec(a:cmd)
endfunction

" Internal: Kill current process on neoterm. (Send a <C-c>)
function! neoterm#kill()
  silent call g:neoterm.last().kill()
endfunction

function! neoterm#list(arg_lead, cmd_line, cursor_pos)
  return filter(keys(g:neoterm.instances), 'v:val =~? "'. a:arg_lead. '"')
endfunction

function! neoterm#get_current_tab_term_all()
  let l:instances = g:neoterm.instances
  let l:tabnr = tabpagenr()
  let l:terms = []
  for l:t in values(l:instances)
    if l:t.parent_tab_id == l:tabnr
      call add(l:terms, l:t)
    endif
  endfor
  return l:terms
endfunction

function! neoterm#current_tab_has_term()
  return len(neoterm#get_current_tab_term_all()) > 0
endfunction

function! neoterm#get_current_tab_term()
  if neoterm#current_tab_has_term()
    let l:target_neoterm = neoterm#get_current_tab_term_all()
    return l:target_neoterm[-1]
  endif
endfunction

function! neoterm#term_exists(term)
  let l:buffer_id = a:term.buffer_id
  return bufexists(l:buffer_id) > 0 && bufwinnr(l:buffer_id) != -1
endfunction

