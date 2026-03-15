-- highlight yank
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({ timeout = 200, visual = true })
	end,
})

-- no auto-continue comments
vim.api.nvim_create_autocmd({ "FileType" }, {
  callback = function()
    vim.opt.formatoptions:remove({"c", "r", "o"})
  end
})

-- restore cursor to file position in previous editing session
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		local line_count = vim.api.nvim_buf_line_count(args.buf)
		if mark[1] > 0 and mark[1] <= line_count then
			vim.api.nvim_win_set_cursor(0, mark)
			-- defer centering slightly so it's applied after render
			vim.schedule(function() vim.cmd("normal! zz") end)
		end
	end,
})

-- Toggle cursorline only for the active window
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "WinLeave", "BufLeave" }, {
  callback = function(args)
    local on = (args.event == "WinEnter" or args.event == "BufEnter")
    vim.opt_local.cursorline = on
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "help", "man", "qf" },
  callback = function()
    vim.cmd("wincmd _") -- max height
    vim.cmd("wincmd |") -- max width
  end,
})

-- Equalize splits when terminal window is resized (across tabs)
vim.api.nvim_create_autocmd("VimResized", {
  desc = "Equalize splits on resize",
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- Close “utility buffers” with q / <Esc> (help/qf/etc.)
vim.api.nvim_create_autocmd("FileType", {
  desc = "Close some buffers with q / <Esc>",
  pattern = { "help", "qf", "lspinfo", "checkhealth", "startuptime" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false

    vim.keymap.set("n", "q", ":bd<CR>",   { buffer = ev.buf, silent = true, desc = "Close window" })
    vim.keymap.set("n", "<Esc>", ":bd<CR>",{ buffer = ev.buf, silent = true, desc = "Close window" })
  end,
})

