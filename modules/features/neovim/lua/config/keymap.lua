---@diagnostic disable: different-requires
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

-- buffer navigation
k.set("n", "<leader><Tab>", "<C-^>", { desc = "Toggle last buffer" })
k.set("n", "<C-^>", "<Nop>")

-- Alt-t: toggle terminal
k.set("n", "<A-t>", function() require("plugins.floaterminal").toggle_terminal() end, { desc = "Terminal: toggle" })

-- fzf-lua
local function project_root()
  return vim.fs.root(0, { ".git" }) or vim.fs.root(vim.fn.getcwd(), { ".git" }) or vim.fn.getcwd()
end

k.set("n", "<leader>f", function() require("fzf-lua").files({ cwd = project_root() }) end, { desc = "Find files in project root" })
k.set("n", "<leader>F", function() require("fzf-lua").files({ cwd = vim.uv.os_homedir() }) end, { desc = "Find files ~" })
k.set("n", "<leader>g", function() require("fzf-lua").live_grep_native({ cwd = project_root() }) end, { desc = "Live grep in project root" })
k.set("n", "<leader>ca", function() require("tiny-code-action").code_action() end, { desc = "Code action" })
k.set("n", "<leader>b", function() require("fzf-lua").buffers() end, { desc = "Buffers" })
k.set("n", "<leader>o", function() require("fzf-lua").oldfiles() end, { desc = "Find old files" })
k.set("n", "<leader><space>", function() require("fzf-lua").builtin() end, { desc = "All finders" })

-- mini.nvim
k.set("n", "s", "<Nop>", { desc = "use `cl` or `r`" })

-- gitsigns
k.set("n", "<leader>hp", function() require("gitsigns").preview_hunk() end, { desc = "Preview hunk" })
k.set("n", "<leader>hb", function() require("gitsigns").blame_line({ full = true }) end, { desc = "Blame line" })

-- oil.nvim
k.set("n", "<leader>e", ":Oil --preview<cr>", { silent = true })

-- better J
vim.keymap.set("n", "J", function() require("treesj").toggle() end, { desc = "Toggle split/join node" })
