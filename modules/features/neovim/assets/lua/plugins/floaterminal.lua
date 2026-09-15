local M = {}

local state = {
  buf = -1,
  win = -1,
}

local function hide()
  if vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_hide(state.win)
    state.win = -1
  end
end

local function create()
  local w = math.floor(vim.o.columns * 0.8)
  local h = math.floor(vim.o.lines * 0.8)

  local win_config = {
    style = "minimal",
    relative = "editor",
    width = w,
    height = h,
    col = math.floor((vim.o.columns - w) / 2),
    row = math.floor((vim.o.lines - h) / 2),
    border = vim.o.winborder,
    title = " floaterminal ",
    title_pos = "center",
  }

  local buf = vim.api.nvim_buf_is_valid(state.buf) and state.buf or vim.api.nvim_create_buf(false, false)
  assert(buf ~= 0, "nvim_create_buf failed")

  local win = vim.api.nvim_open_win(buf, true, win_config)
  assert(win ~= 0, "nvim_open_win failed")

  if vim.bo[buf].buftype ~= "terminal" then
    vim.cmd.terminal()
    vim.b[buf].miniindentscope_disable = true
    vim.b[buf].minicursorword_disable = true
    vim.bo[buf].buflisted = false
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].modifiable = false
  end

  vim.cmd.startinsert()

  -- double-tap Esc detection in terminal mode:
  -- two quick Esc -> normal mode; single Esc (after timeout) -> close
  local esc_timer = nil
  vim.keymap.set("t", "<Esc>", function()
    if esc_timer then
      vim.fn.timer_stop(esc_timer)
      esc_timer = nil
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
    else
      esc_timer = vim.fn.timer_start(200, function()
        esc_timer = nil
        hide()
      end)
    end
  end, { buf = buf, desc = "Exit terminal mode (double) or close (single)" })

  vim.keymap.set("n", "<Esc>", hide, { buf = buf, desc = "Hide floaterminal" })

  state.buf = buf
  state.win = win
end

function M.toggle_terminal()
  if vim.api.nvim_win_is_valid(state.win) then
    hide()
  else
    create()
  end
end

return M
