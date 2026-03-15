local k = vim.keymap

-- leader key
vim.g.mapleader = vim.keycode("<Space>")

-- disable arrow keys
k.set({ "n", "i", "v" }, "<Up>", "<Nop>")
k.set({ "n", "i", "v" }, "<Down>", "<Nop>")
k.set({ "n", "i", "v" }, "<Left>", "<Nop>")
k.set({ "n", "i", "v" }, "<Right>", "<Nop>")

-- Clear search highlight with escape
k.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- quickfix
k.set("n", "<leader>co", "<cmd>copen<CR>", { desc = "Quickfix: open" })
k.set("n", "<leader>cn", "<cmd>cnext<CR>zz", { desc = "Quickfix: next" })
k.set("n", "<leader>cp", "<cmd>cprev<CR>zz", { desc = "Quickfix: prev" })

-- Center screen on jumps
k.set("n", "<C-d>", "<C-d>zz")
k.set("n", "<C-u>", "<C-u>zz")

-- normalize spacing + trim trailing whitespace + clear search highlight
k.set("n", "ss", [[:%s/\S\zs\s\+/ /g | %s/\s\+$//e | nohlsearch<CR>]], { desc = "Normalize spacing" })

-- Keep selection when indenting
k.set("v", "<", "<gv")
k.set("v", ">", ">gv")

-- save & write
k.set("n", "<leader>w", vim.cmd.write, { desc = "Save buffer" })
k.set("n", "<leader>q", vim.cmd.quitall, { desc = "Quit all" })
k.set("n", "<C-q>", function() vim.api.nvim_buf_delete(0, {}) end, { desc = "Close buffer" })

-- Alt-t: toggle in both normal + terminal mode
k.set("n", "<A-t>", function() require("floaterminal").toggle_terminal() end, { desc = "Terminal: toggle" })
