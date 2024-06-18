# Beacon.nvim - never lose your cursor again!

Highlight cursor when it moves, changes windows and more!
This plugin is heavily inspired by emacs package [beacon](https://github.com/Malabarba/beacon).

![example.gif](https://user-images.githubusercontent.com/1163040/86011926-be2f6980-ba36-11ea-956b-a377dcc7fafb.gif)

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{ 'danilamihailov/beacon.nvim', config = true } -- lazy calls setup() by itself
```

Or use your favorite plugin manager, you'll need to call setup `require('beacon').setup()`

For vim versions checkout previous tags `v1.x.x`

## Customization

### Default config

```lua
 {
  enabled = true, --- (boolean | fun():boolean) check if enabled
  speed = 2, --- integer speed at wich animation goes
  width = 40, --- integer width of the beacon window
  winblend = 70, --- integer starting transparency of beacon window :h winblend
  fps = 60, --- integer how smooth the animation going to be
  min_jump = 10, --- integer what is considered a jump. Number of lines
}
```

### Changing color

Beacon is highlighted by `Beacon` group, so you can change it like this:

```lua
vim.api.nvim_set_hl(0, 'Beacon', { bg = 'white', ctermbg = 15, default = true })
```

use `guibg` if you have `termguicolors` enabled, otherwise use `ctermbg`.

> NOTE:
> checkout doc/beacon.txt for more

## Similar plugins

- Locate cursor after search https://github.com/inside/vim-search-pulse
