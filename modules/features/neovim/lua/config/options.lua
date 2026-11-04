local o = vim.opt

o.expandtab = true
o.shiftwidth = 2
o.softtabstop = 2
o.tabstop = 2

o.linebreak = true
o.showbreak = "↳ "
o.breakindent = true
o.breakindentopt = "shift:2"

o.number = true
o.relativenumber = true
o.scrolloff = 4
o.smoothscroll = true

o.ignorecase = true
o.smartcase = true

o.termguicolors = true
o.laststatus = 3
o.winborder = "rounded"
o.list = true
o.updatetime = 250 -- CursorHold for diagnostics and gitsigns

o.splitbelow = true
o.splitright = true

o.swapfile = false
o.undofile = true
o.confirm = true

o.mouse = ""

-- deferred: the clipboard provider check slows startup
vim.schedule(function()
  o.clipboard = "unnamedplus"
end)
