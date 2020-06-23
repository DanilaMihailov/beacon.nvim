" highlight used for floating window
highlight BeaconDefault guibg=white ctermbg=15

" if user overriden highlight, then we do not touch it
if !hlexists("Beacon")
    hi! link Beacon BeaconDefault
endif

let g:beacon_size = get(g:, 'beacon_size', 40)
let g:beacon_fade = get(g:, 'beacon_fade', 1)
let g:beacon_minimal_jump = get(g:, 'beacon_minimal_jump', 10)
let g:beacon_show_jumps = get(g:, 'beacon_show_jumps', 1)
let g:beacon_shrink = get(g:, 'beacon_shrink', 1)
let g:beacon_timeout = get(g:, 'beacon_timeout', 0)
" for future
let g:beacon_ignore_buffers = get(g:, 'beacon_timeout', [])

" buffer needed for floating window
let s:fake_buf = nvim_create_buf(v:false, v:true)
let s:float = 0 " floating win id

let s:fade_timer = 0

" stop timers and remove floatng window
function! s:Clear_highlight(...)
    if s:fade_timer > 0
        call timer_stop(s:fade_timer)
    endif

    if s:float > 0
        call nvim_win_close(s:float, 0)
        let s:float = 0
    endif
endfunction

" smoothly fade out window and then close it
function! s:Fade_window(...)
    if s:float > 0
        let l:old = nvim_win_get_option(s:float, "winblend")
        if g:beacon_shrink
            let l:old_cols = nvim_win_get_width(s:float)
        else
            let l:old_cols = 40
        endif

        if l:old > 80
            let l:speed = 2
        else
            let l:speed = 1
        endif

        if l:old == 100 || l:old_cols == 10
            call s:Clear_highlight()
            return
        endif
        call nvim_win_set_option(s:float, 'winblend', l:old + l:speed)
        if g:beacon_shrink
            " some bug with set_width E315 and E5555, when scrolloff set to 8
            call nvim_win_set_width(s:float, l:old_cols - l:speed)
        endif
    endif
endfunction

" get current cursor position and show floating window there
function! s:Highlight_position(...)
    " get some bugs when enabled in fugitive
    if nvim_buf_get_option(0, "ft") == "fugitive"
        return
    endif

    " already showing, close old window
    if s:float > 0
        call s:Clear_highlight()
    endif

    let l:win = nvim_win_get_config(0)
    " moves happening in floating window, ignore them
    if has_key(l:win, "relative") && l:win.relative != ""
        return
    endif

    let l:opts = {'relative': 'win', 'width': g:beacon_size,  'bufpos': [line(".")-1, col(".")], 'height': 1, 'col': 0,
        \ 'row': 0, 'anchor': 'NW', 'style': 'minimal', 'focusable': v:false}
    let s:float = nvim_open_win(s:fake_buf, 0, l:opts)

    call nvim_win_set_option(s:float, 'winhl', 'Normal:Beacon')
    call nvim_win_set_option(s:float, 'winblend', 70)

    if g:beacon_fade
        let s:fade_timer = timer_start(16, funcref("s:Fade_window"), {'repeat': 35})
    endif

    if g:beacon_timeout
        call timer_start(g:beacon_timeout, funcref("s:Clear_highlight"), {'repeat': 1})
    endif

endfunction

let s:prev_cursor = 0
" highlight position if cursor moved significally
function! s:Cursor_moved()
    let l:cur = line(".")
    let l:diff = l:cur - s:prev_cursor

    if l:diff > g:beacon_minimal_jump || l:diff < g:beacon_minimal_jump * -1
        call s:Highlight_position()
    endif

    let s:prev_cursor = l:cur
endfunction

augroup BeaconHighlightMoves
    autocmd!
    if g:beacon_show_jumps
        autocmd CursorMoved * call s:Cursor_moved()
    endif
    autocmd BufWinEnter * call s:Highlight_position()
    autocmd WinEnter * call s:Highlight_position()
augroup end
