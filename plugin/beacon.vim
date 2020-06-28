" do not load plugin twice (get weird errors)
if get(g:, "beacon_loaded", 0)
    finish
endif

if has("nvim")
    if !has("nvim-0.4.0")
        echoerr "Beacon only supports neovim version 0.4+ and vim 8.2+ for now"
        finish
    endif
else
    if v:version < 802
        echoerr "Beacon only supports neovim version 0.4+ and vim 8.2+ for now"
        finish
    endif
endif

let g:beacon_loaded = 1

" highlight used for floating window
if has("nvim")
    highlight BeaconDefault guibg=white ctermbg=15
else
    highlight BeaconDefault guibg=silver ctermbg=7
endif


" if user overriden highlight, then we do not touch it
if !hlexists("Beacon")
    hi! link Beacon BeaconDefault
endif

let g:beacon_enable = get(g:, 'beacon_enable', 1) 
let g:beacon_size = get(g:, 'beacon_size', 40)
let g:beacon_fade = get(g:, 'beacon_fade', 1)
let g:beacon_minimal_jump = get(g:, 'beacon_minimal_jump', 10)
let g:beacon_show_jumps = get(g:, 'beacon_show_jumps', 1)
let g:beacon_shrink = get(g:, 'beacon_shrink', 1)
let g:beacon_timeout = get(g:, 'beacon_timeout', 500)
let g:beacon_ignore_buffers = get(g:, 'beacon_ignore_buffers', [])

" buffer needed for floating window
if has("nvim")
    let s:fake_buf = nvim_create_buf(v:false, v:true)
endif
let s:float = 0 " floating win id

let s:fade_timer = 0
let s:close_timer = 0

fun! s:IsIgnoreBuffer()
    let name = bufname()

    for i in g:beacon_ignore_buffers
        if name =~ i
            return 1
        endif
    endfor
    return 0
endf

" stop timers and remove floatng window
function! s:Clear_highlight(...) abort
    if s:fade_timer > 0
        call timer_stop(s:fade_timer)
    endif

    if s:close_timer > 0
        call timer_stop(s:close_timer)
    endif

    if has("nvim")
        if s:float > 0 && nvim_win_is_valid(s:float)
            call nvim_win_close(s:float, 0)
            let s:float = 0
        endif
    else
        call popup_close(s:float)
    endif
endfunction

" smoothly fade out window and then close it
function! s:Fade_window(...) abort
    if has("nvim")
        if s:float > 0 && nvim_win_is_valid(s:float)
            let l:old = nvim_win_get_option(s:float, "winblend")
            if g:beacon_shrink
                let l:old_cols = nvim_win_get_width(s:float)
            else
                let l:old_cols = 40
            endif

            if l:old > 90
                let l:speed = 3
            elseif l:old > 80
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
                try
                    call nvim_win_set_width(s:float, l:old_cols - l:speed)
                catch /.*/
                    
                endtry
            endif
        endif
    else
        if s:float > 0 && g:beacon_shrink
            let l:old_cols = get(popup_getpos(s:float), 'width', 1)

            if l:old_cols < 20
                let l:speed = 5
            elseif l:old_cols < 30
                let l:speed = 4
            else
                let l:speed = 3
            endif

            if l:old_cols == 1
                call s:Clear_highlight()
                return
            endif

            call popup_setoptions(s:float, {'maxwidth': l:old_cols - l:speed})
        endif
    endif
endfunction

" get current cursor position and show floating window there
function! s:Highlight_position(force) abort
    if g:beacon_enable == 0 && a:force == v:false
        return
    endif

    if s:IsIgnoreBuffer()
        return
    endif

    " get some bugs when enabled in fugitive
    if has("nvim")
        if nvim_buf_get_option(0, "ft") == "fugitive"
            return
        endif
    endif

    " already showing, close old window
    if s:float > 0
        call s:Clear_highlight()
    endif

    if has("nvim")
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
    else

        let l:cur_line = line('.')
        let l:cur_col = col('.')
        let l:win_id = win_getid()

        " get text under cursor
        let l:text = substitute(strtrans(strcharpart(getbufline('%', l:cur_line)[0], l:cur_col - 1, g:beacon_size)), '\^I', repeat(' ', &tabstop), 'g')

        let l:i = 0
        let l:hls = []

        " get highlights of each character and save them
        while l:i <= strdisplaywidth(l:text)
            let l:hi = synIDattr(synID(l:cur_line, l:i + l:cur_col, 0), "name")
            if l:hi == ''
                let l:i += 1
                continue
            endif
            let l:prop_name = "BeaconProp".l:i.l:win_id
            call prop_type_delete(l:prop_name)
            call prop_type_add(l:prop_name, {'highlight': l:hi})
            call add(l:hls, {'col': l:i + 1, 'type': l:prop_name, 'hi': l:hi})
            let l:i += 1
        endwhile

        let l:diff = g:beacon_size - strlen(l:text)
        if  l:diff > 0
            let l:text .= repeat(" ", l:diff)
        endif

        try
            let s:float = popup_create([{'text': l:text, 'props': l:hls}], #{
                \ pos: 'botleft',
                \ line: 'cursor',
                \ col: 'cursor',
                \ moved: 'any',
                \ wrap: v:false,
                \ highlight: 'Beacon'
            \ })
        catch
            
        endtry
    endif

    if g:beacon_fade
        let s:fade_timer = timer_start(16, funcref("s:Fade_window"), {'repeat': -1})
    endif

    let s:close_timer = timer_start(g:beacon_timeout, funcref("s:Clear_highlight"), {'repeat': 1})

endfunction

let s:prev_cursor = 0
" highlight position if cursor moved significally
function! s:Cursor_moved()
    let l:cur = line(".")
    let l:diff = abs(l:cur - s:prev_cursor)

    if l:diff > g:beacon_minimal_jump
        let l:prev_fold = foldclosed(s:prev_cursor) 
        let l:prev_fold_end = foldclosedend(s:prev_cursor) 
        let l:cur_fold = foldclosed(l:cur) 
        let l:cur_fold_end = foldclosedend(l:cur) 

        " if we move over fold, substract fold lines from diff
        if l:prev_fold > -1 && l:prev_fold_end > -1
            let l:diff -= l:prev_fold_end - l:prev_fold
        endif

        " if we move over fold, substract fold lines from diff
        if l:cur_fold > -1 && l:cur_fold_end > -1
            let l:diff -= l:cur_fold_end - l:cur_fold
        endif

        " check diff again before highlight
        if l:diff > g:beacon_minimal_jump
            call s:Highlight_position(v:false)
        endif
    endif

    let s:prev_cursor = l:cur

endfunction

function! s:Beacon_toggle() abort
    if g:beacon_enable
        let g:beacon_enable = 0
    else
        let g:beacon_enable = 1
    endif
endfunction

command! Beacon call s:Highlight_position(v:true)
command! BeaconToggle call s:Beacon_toggle()
command! BeaconOn let g:beacon_enable = 1
command! BeaconOff let g:beacon_enable = 0

augroup BeaconHighlightMoves
    autocmd!
    if g:beacon_show_jumps
        autocmd CursorMoved * call s:Cursor_moved()
    endif
    " autocmd BufWinEnter * call s:Highlight_position()
    " autocmd FocusGained * call s:Highlight_position()
    autocmd WinEnter * call s:Highlight_position(v:false)
augroup end
