# Beacon.nvim - see your cursor jump
Whenever cursor jumps some distance or moves between windows, it will flash so you can see where it is. This plugin is heavily inspired by emacs package [beacon](https://github.com/Malabarba/beacon).

**Note**: this plugin only works in [NeoVim](https://github.com/neovim/neovim).

## Installation

### [vim-plug](https://github.com/junegunn/vim-plug)
1. Add the following configuration to your `.vimrc`.

        Plug 'danilamihailov/beacon.nvim'

2. Install with `:PlugInstall`.

Or use your favorite plugin manager

## Customization

### Changing color
Beacon is highlighted by `Beacon` group, so you can change it like this:
```viml
highlight Beacon guibg=white ctermbg=15
```
use `guibg` if you have `termguicolors` enabled, otherwise use `ctermbg`.

### Changing beacon size
```viml
let g:beacon_size = 40
```

### When to show beacon
If you **only** want to see beacon when cursor changes windows, you can set
```viml
let g:beacon_show_jumps = 0
```
and it will ignore jumps inside buffer. By default shows all jumps.

You can change what beacon considers significant jump, by changing
```viml
let g:beacon_minimal_jump = 10
```

# How it works
Whenever plugin detects some kind of a jump, it's showing floating window at the cursor position and using `winblend` fades window out.
