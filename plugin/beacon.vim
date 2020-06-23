echo "autoload" 
highlight Beacon guibg=gray

redir => s:original
    silent! highlight CursorLine
redir END

function s:Clear_highlight(...)
    for m in getmatches()
        if m.group == "Beacon"
            call matchdelete(m.id)
        endif
    endfor
    execute "highlight CursorLine " . matchstr(s:original, 'ctermbg=#\?\w\+') matchstr(s:original, 'guibg=#\?\w\+')
endfunction

function s:Highlight_position()
    if col("$") < 10
        highlight! CursorLine guibg=gray
    endif
    call matchaddpos("Beacon", [[line("."), col("."), 20], 34])
    call timer_start(500, funcref("s:Clear_highlight"))
endfunction

autocmd BufWinEnter * call s:Highlight_position()
autocmd WinEnter * call s:Highlight_position()
autocmd WinLeave * call s:Clear_highlight()
