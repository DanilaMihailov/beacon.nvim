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
