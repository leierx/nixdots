-- highlight yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

-- no auto-continue comments
vim.api.nvim_create_autocmd({ "FileType" }, {
  callback = function()
    vim.opt.formatoptions:remove({ "r", "o" })
  end,
})

-- restore cursor to file position in previous editing session
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
      vim.schedule(function() vim.cmd("normal! zz") end)
    end
  end,
})

-- toggle cursorline only for the active window
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "WinLeave", "BufLeave" }, {
  callback = function(args)
    local on = (args.event == "WinEnter" or args.event == "BufEnter")
    vim.opt_local.cursorline = on
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "help", "man", "qf" },
  callback = function()
    vim.cmd("wincmd _")
    vim.cmd("wincmd |")
  end,
})

-- equalize splits when terminal window is resized (across tabs)
vim.api.nvim_create_autocmd("VimResized", {
  desc = "Equalize splits on resize",
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- close utility buffers with q / <Esc>
vim.api.nvim_create_autocmd("FileType", {
  desc = "Close some buffers with q / <Esc>",
  pattern = { "help", "qf", "lspinfo", "checkhealth", "startuptime" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", ":bd<CR>", { buf = ev.buf, silent = true, desc = "Close window" })
    vim.keymap.set("n", "<Esc>", ":bd<CR>", { buf = ev.buf, silent = true, desc = "Close window" })
  end,
})

-- `:restart` drops command-line files; reopen the focused file on the new server
local function restart_file()
  local function is_file(buf)
    return buf > 0
      and vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].buftype == ""
      and vim.api.nvim_buf_get_name(buf) ~= ""
  end

  for _, buf in ipairs({ vim.api.nvim_get_current_buf(), vim.fn.bufnr("#") }) do
    if is_file(buf) then
      return vim.api.nvim_buf_get_name(buf)
    end
  end
end

vim.api.nvim_create_user_command("Restart", function()
  local file = restart_file()
  vim.cmd(file and ("restart edit " .. vim.fn.fnameescape(file)) or "restart")
end, { desc = "Restart, reopening the focused file" })

vim.cmd([[cnoreabbrev <expr> restart (getcmdtype() ==# ':' && getcmdline() ==# 'restart') ? 'Restart' : 'restart']])
