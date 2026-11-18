local M = {}

local buf, win = -1, -1

local function geometry()
  local w = math.floor(vim.o.columns * 0.8)
  local h = math.floor(vim.o.lines * 0.8)
  return {
    relative = "editor",
    width = w,
    height = h,
    col = math.floor((vim.o.columns - w) / 2),
    row = math.floor((vim.o.lines - h) / 2),
  }
end

local function hide()
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_hide(win)
  end
  win = -1
end

local function setup_buffer()
  vim.fn.jobstart(vim.o.shell, { term = true })
  vim.b[buf].miniindentscope_disable = true
  vim.b[buf].minicursorword_disable = true
  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = "hide"

  -- nvim only wipes a terminal that exited 0
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = buf,
    once = true,
    callback = function(ev)
      vim.schedule(function()
        hide()
        if vim.api.nvim_buf_is_valid(ev.buf) then
          vim.api.nvim_buf_delete(ev.buf, { force = true })
        end
      end)
    end,
  })

  -- one <Esc> goes to the program; a second within 200 ms leaves terminal mode
  local last_esc = 0
  vim.keymap.set("t", "<Esc>", function()
    local now = vim.uv.now()
    if now - last_esc < 200 then
      last_esc = 0
      vim.api.nvim_feedkeys(vim.keycode("<C-\\><C-n>"), "n", false)
    else
      last_esc = now
      vim.api.nvim_chan_send(vim.bo[buf].channel, "\27")
    end
  end, { buf = buf, desc = "Esc to the program; twice for normal mode" })
  vim.keymap.set("n", "<Esc>", hide, { buf = buf, desc = "Hide floaterminal" })
end

local function open()
  local fresh = not vim.api.nvim_buf_is_valid(buf)
  if fresh then
    buf = vim.api.nvim_create_buf(false, false)
  end

  win = vim.api.nvim_open_win(buf, true, vim.tbl_extend("force", geometry(), {
    style = "minimal",
    border = vim.o.winborder,
    title = " floaterminal ",
    title_pos = "center",
  }))
  vim.wo[win].winfixbuf = true

  if fresh then
    setup_buffer()
  end
  vim.cmd.startinsert()
end

function M.toggle_terminal()
  local shown_here = vim.api.nvim_win_is_valid(win)
    and vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage()
  hide()
  if not shown_here then
    open()
  end
end

vim.api.nvim_create_autocmd("VimResized", {
  desc = "Keep the floaterminal at 80% of the editor",
  callback = function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_config(win, geometry())
    end
  end,
})

return M
