local git = require("git.custom-functions")
local map = vim.keymap.set
local cmd = vim.cmd

-- leader
vim.g.mapleader = ' '

-- unbindings
map("", "<Space>", "<Nop>")
map("", "s", "<Nop>")

-- Norwegian keyboard remap
vim.opt.langmap = 'ø[,Ø{,æ],Æ}'

-- Visual-mode: Remove unnessecary spaces
-- map("v", "<leader>ss", [[:s/\v(\S)\zs\s{2,}/ /g | nohlsearch<CR>]], { desc = "Squash spaces (selection, keep indent)" })

-- Search
map("n", "<leader>h", function() vim.opt.hlsearch = not vim.opt.hlsearch:get() end, { desc = "Toggle search highlight" })
map({ "n", "v" }, ",", "/", { desc = "Start / search" })

-- basic save & quit
map("n", "<leader>w", function() cmd.write() end, { silent = true, desc = "Write file" })
map("n", "<leader>q", function() cmd("qa") end, { silent = true, desc = "Quit window" })

-- buffers
map("n", "L", cmd.bnext, { desc = "Switch to next Buffer", noremap = true, silent = true })
map("n", "H", cmd.bprev, { desc = "Switch to prev Buffer", noremap = true, silent = true })
map("n", "<C-q>", function() cmd("bw") end, { desc = "Close Buffer" })

-- paste
map("n", "<leader>p", '"_dP')

-- lsp diagnostics
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostics in float" })

-- reselecting after block indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- resession
map("n", "<leader>ss", function()
  vim.ui.input({ prompt = "Session name: " }, function(input)
    if input and input ~= "" then
      require("resession").save(input)
    end
  end)
end, { silent = true, desc = "Session • Save" })
map("n", "<leader>sr", function() require("resession").load("last") end, { silent = true, desc = "Session • Restore last" })

-- Floating term
map("n", "<leader><CR>", function() Snacks.terminal() end, { desc = "Toggle floating terminal" })

-- oil
map("n", "<leader>e", function() require("oil").open() end, { desc = "toggle Oil" })

-- Git
map("n", "<leader>ga", git.commit_and_push, { desc = "Git add → commit → push" })

-- flash
map({ "n", "x", "o" }, "S", function() require("flash").jump() end, { desc = "Flash jump", noremap = true })

-- telescope
map("n", "<leader>ff", function() require("telescope.builtin").find_files() end, { desc = "Find files (cwd)", noremap = true, silent = true })
map("n", "<leader>fF", function() require("telescope.builtin").find_files({ cwd = vim.loop.os_homedir() }) end, { desc = "Find files (home)", noremap = true, silent = true })
map("n", "<leader>fb", function() require("telescope.builtin").buffers() end, { desc = "Manage Buffers", noremap = true, silent = true })
map("n", "<leader>fo", function() require("telescope.builtin").oldfiles() end, { desc = "Old files", noremap = true, silent = true })
map("n", "<leader>fg", function() require("telescope.builtin").live_grep() end, { desc = "Grep (cwd)", noremap = true, silent = true })
map("n", "<leader>fG", function() require("telescope.builtin").live_grep({ cwd = vim.loop.os_homedir() }) end, { desc = "Grep (home)", noremap = true, silent = true })
map("n", "<leader>fs", function() require("telescope").extensions.resession.resession() end, { desc = "Search sessions", noremap = true, silent = true })
