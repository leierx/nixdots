local M = {}

-- invalid buffer & window
M.state = { buffer = -1, window = -1, timer = (vim.uv or vim.loop).new_timer() }

M.hide = function ()
  if vim.api.nvim_win_is_valid(M.state.window) then
    vim.api.nvim_win_hide(M.state.window)
  end
end

-- render new window, reuse same buffer
M.create_window = function ()
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2 - 2)

  local win_config = {
    title = "floaterminal",
    title_pos = "center",
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
  }

  -- create new or reuse same buffer
  local buf = vim.api.nvim_buf_is_valid(M.state.buffer) and M.state.buffer or vim.api.nvim_create_buf(false, false)
  assert(buf ~= 0, "nvim_create_buf() failed")

  -- create window
  local win = vim.api.nvim_open_win(buf, true, win_config)
  assert(win ~= 0, "nvim_open_win() failed")

  -- start terminal
  if vim.bo.buftype ~= "terminal" then
    vim.cmd.terminal()
    -- buffer options
    vim.api.nvim_buf_set_var(buf, "miniindentscope_disable", true)
    vim.api.nvim_buf_set_var(buf, "minicursorword_disable", true)
    vim.api.nvim_set_option_value("buflisted", false, { buf = buf })
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  end

  -- start insert
  vim.cmd.startinsert()

  -- keymaps
  vim.keymap.set("t", "<Esc>", function()
    if M.state.timer:is_active() then
      M.state.timer:stop()
      vim.api.nvim_feedkeys( vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "t", false)
      return
    end

    M.state.timer:start(150, 0, function() vim.schedule(M.hide) end)
  end, { buffer = buf })

  vim.keymap.set("n", "<Esc>", function() M.hide() end, { buffer = buf })

  -- set state
  M.state.buffer = buf
  M.state.window = win
end

M.toggle_terminal = function ()
  if not vim.api.nvim_win_is_valid(M.state.window) then
    M.create_window()
    return
  end

  M.hide()
end

return M
