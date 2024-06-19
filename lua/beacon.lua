local M = {}

---@class beacon.DefaultConfig
---@field enabled (boolean | fun():boolean) check if enabled (default: true)
---@field speed integer speed at wich animation goes (default: 2)
---@field width integer width of the beacon window (default: 40)
---@field winblend integer starting transparency of beacon window :h winblend (default: 70)
---@field fps integer how smooth the animation going to be (default: 60)
---@field min_jump integer what is considered a jump. Number of lines (default: 10)
local default_config = {
  enabled = true,
  speed = 2,
  width = 40,
  winblend = 70,
  fps = 60,
  min_jump = 10,
}

-- weird behaviour in oil window
local ignore_fts = { 'oil' }

---@type beacon.DefaultConfig
M.config = {}

local fake_buffer = vim.api.nvim_create_buf(false, true)

---@package
---Creates small floating window
---@param cfg beacon.DefaultConfig
---@return integer window window number
local function create_window(cfg)
  local window = vim.api.nvim_open_win(fake_buffer, false, {
    relative = 'cursor',
    row = 0,
    col = 0,
    width = cfg.width,
    height = 1,
    style = 'minimal',
    focusable = false,
    noautocmd = true,
  })

  vim.wo[window].winblend = cfg.winblend
  vim.wo[window].winhl = 'Normal:Beacon'

  return window
end

---Highligts cursor at current position using beacon
function M.highlight_cursor()
  local cfg = M.config
  if cfg.enabled == false or vim.is_callable(cfg.enabled) and not cfg.enabled() then
    return
  end

  if vim.list_contains(ignore_fts, vim.bo.ft) then
    return
  end

  -- ignore preview window
  if vim.wo.previewwindow then
    return
  end

  -- ignore floating windows
  if vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative ~= '' then
    return
  end

  local win = create_window(cfg)
  local fade_timer = vim.loop.new_timer()
  local ms = (1 / cfg.fps) * 1000
  fade_timer:start(
    0,
    ms,
    vim.schedule_wrap(function()
      if not vim.api.nvim_win_is_valid(win) then
        pcall(fade_timer.close, fade_timer)
        return
      end

      local winblend = vim.wo[win].winblend
      vim.wo[win].winblend = winblend + cfg.speed

      local width = vim.api.nvim_win_get_width(win)
      vim.api.nvim_win_set_width(win, width - cfg.speed)

      if width == 0 or winblend == 100 then
        pcall(fade_timer.close, fade_timer)
        vim.api.nvim_win_close(win, true)
      end
    end)
  )
end

---@package
---Checks if cursor moved enough and if it did calls `highlight_cursor`
---@param event beacon.AutocmdEvent
local function cursor_moved(event)
  if not vim.api.nvim_buf_is_loaded(event.buf) then
    return
  end
  local prev_cursor = vim.b[event.buf].beacon_prev_cursor or 0
  local prev_abs = vim.b[event.buf].beacon_prev_abs or 0

  local cfg = M.config
  local cur = vim.fn.winline()
  local cur_abs = vim.fn.line '.'
  local diff = math.abs(cur - prev_cursor)
  local abs_diff = math.abs(cur_abs - prev_abs)

  if diff > cfg.min_jump and abs_diff > cfg.min_jump then
    M.highlight_cursor()
  end

  vim.b[event.buf].beacon_prev_cursor = cur
  vim.b[event.buf].beacon_prev_abs = cur_abs
end

---Event for callback in nvim_create_autocmd
---@package
---@class beacon.AutocmdEvent
---@field id number autocommand id
---@field event string name of the triggered event
---@field group number|nil autocommand group id, if any
---@field match string expanded value of <amatch>
---@field buf number expanded value of <abuf>
---@field file string expanded value of <afile>
---@field data any arbitrary data passed from nvim_exec_autocmds()

---Setting up plugin
---@param config? beacon.DefaultConfig
function M.setup(config)
  M.config = vim.tbl_extend('force', default_config, config or {})

  vim.api.nvim_set_hl(0, 'Beacon', { bg = 'white', ctermbg = 15, default = true })

  local beacon_group = vim.api.nvim_create_augroup('beacon_group', { clear = true })

  vim.api.nvim_create_autocmd({ 'WinEnter', 'FocusGained' }, {
    pattern = '*',
    group = beacon_group,
    desc = 'Highlight cursor',
    callback = function()
      vim.schedule(M.highlight_cursor)
    end,
  })
  vim.api.nvim_create_autocmd('CursorMoved', {
    pattern = '*',
    group = beacon_group,
    desc = 'Highlight cursor moves',
    ---@param event beacon.AutocmdEvent
    callback = function(event)
      vim.schedule(function()
        cursor_moved(event)
      end)
    end,
  })
end

return M
