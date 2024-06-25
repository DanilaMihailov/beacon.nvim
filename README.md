# Beacon.nvim - never lose your cursor again!

Highlight cursor when it moves, changes windows and more!
This plugin is heavily inspired by emacs package [beacon](https://github.com/Malabarba/beacon).

https://github.com/DanilaMihailov/beacon.nvim/assets/1163040/df4a603e-66c7-4bdb-9704-54a168d59ee7

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{ 'danilamihailov/beacon.nvim' } -- lazy calls setup() by itself
```

Or use your favorite plugin manager, you'll need to call setup `require('beacon').setup()`

> [!NOTE]
> For Vim versions checkout v1 tags [v1.3.4](https://github.com/DanilaMihailov/beacon.nvim/tree/v1.3.4)

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
  cursor_events = { 'CursorMoved' }, -- table<string> what events trigger check for cursor moves
  window_events = { 'WinEnter', 'FocusGained' }, -- table<string> what events trigger cursor highlight
  highlight = { bg = 'white', ctermbg = 15 }, -- vim.api.keyset.highlight table passed to vim.api.nvim_set_hl
}
```

### Changing color

Beacon is highlighted by `Beacon` group, so you can change it like this:

```lua
vim.api.nvim_set_hl(0, 'Beacon', { bg = 'white' })
```

or simplier way is to change `highlight` params in config

check `:help nvim_set_hl()` for more options.

> [!NOTE]
> checkout doc/beacon.txt for more

## Similar plugins

- Locate cursor after search https://github.com/inside/vim-search-pulse
