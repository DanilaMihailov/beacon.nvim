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
let g:beacon_focus_gained = get(g:, 'beacon_focus_gained', 0)
let g:beacon_shrink = get(g:, 'beacon_shrink', 1)
let g:beacon_timeout = get(g:, 'beacon_timeout', 500)
let g:beacon_ignore_buffers = get(g:, 'beacon_ignore_buffers', [])
let g:beacon_ignore_filetypes = get(g:, 'beacon_ignore_filetypes', [])

" buffer needed for floating window
if has("nvim")
    let s:fake_buf = nvim_create_buf(v:false, v:true)
endif
let s:float = 0 " floating win id

let s:fade_timer = 0
let s:close_timer = 0

fun! s:IsIgnoreFiletype()
    let name = &filetype

    " get some bugs when enabled in fugitive
    if name == "fugitive"
        return 1
    endif

    for i in g:beacon_ignore_filetypes
        if name =~ i
            return 1
        endif
    endfor
    return 0
endf

fun! s:IsIgnoreBuffer()
    let name = bufname()

    " detect if we are inside command line window 
    " (some weird behaviour in neovim 0.5)
    if getcmdwintype() != '' || getcmdline() != '' || getcmdtype() != '' || getcmdpos() > 0
        return 1
    endif

    if name == '[Command line]'
        return 1
    endif

    for i in g:beacon_ignore_buffers
        if name =~ i
            return 1
        endif
    endfor
    return 0
endf

" stop timers and remove floatng window
function! s:Clear_highlight(...) abort
    try
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
    catch
        
    endtry
endfunction

" smoothly fade out window and then close it
function! s:Fade_window(...) abort
    try
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
                    call nvim_win_set_width(s:float, l:old_cols - l:speed)
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
    catch
        
    endtry
endfunction

" get current cursor position and show floating window there
function! s:Highlight_position(force) abort
    if g:beacon_enable == 0 && a:force == v:false
        return
    endif

    if s:IsIgnoreBuffer()
        return
    endif

    if s:IsIgnoreFiletype()
        return
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
let s:prev_abs = 0
" highlight position if cursor moved significally
function! s:Cursor_moved()
    let l:cur = winline()
    let l:cur_abs = line(".")
    let l:diff = abs(l:cur - s:prev_cursor)
    let l:abs_diff = abs(l:cur_abs - s:prev_abs)

    " absolute line number diff needed to migigate showing beacon
    " when <C-E> or <C-Y> moved more than min lines
    if l:diff > g:beacon_minimal_jump && l:abs_diff > g:beacon_minimal_jump
        call s:Highlight_position(v:false)
    endif

    let s:prev_cursor = l:cur
    let s:prev_abs = l:cur_abs

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
        silent autocmd CursorMoved * call s:Cursor_moved()
    endif
    " autocmd BufWinEnter * call s:Highlight_position()
    if g:beacon_focus_gained
        silent autocmd FocusGained * call s:Highlight_position(v:false)
    endif
    silent autocmd WinEnter * call s:Highlight_position(v:false)
    silent autocmd CmdwinLeave * call s:Clear_highlight()
augroup end
