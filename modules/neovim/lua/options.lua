local o = vim.opt

-- Wrapping
o.linebreak = true -- wrap at word boundaries (not mid-word)
o.showbreak = "↳ " -- prefix for wrapped lines
o.breakindent = true -- keep indentation on wrapped lines
o.breakindentopt = "shift:2"

-- UI
o.cmdheight = 0 -- use the cmdline only when needed (experimental)
o.laststatus = 3 -- global statusline
o.showcmd = false -- redundant/noisy with cmdheight=0
o.termguicolors = true -- 24-bit colors
o.winborder = "rounded" -- default border style for floating windows
o.completeopt = { "menuone", "noselect" }
o.list = true -- show invisible characters
o.listchars = { trail = "·" } -- show trailing spaces

-- Indentation & tabs
o.expandtab = true -- insert spaces instead of literal tabs
o.shiftwidth = 2 -- indent size for << and >>, autoindent, etc.
o.autoindent = true -- keep indentation from previous line
o.smartindent = false -- avoid weird language guesses
o.softtabstop = 2 -- <Tab>/<BS> behave like 2-space indent steps
o.tabstop = 2 -- visual width of a tab character

-- Line numbers & scrolling
o.number = true
o.relativenumber = true
o.scrolloff = 4 -- keep a little context above/below the cursor

-- Search
o.ignorecase = true -- case-insensitive search...
o.smartcase = true -- ...unless the pattern contains uppercase

-- Splits
o.splitbelow = true -- new horizontal splits go below
o.splitright = true -- new vertical splits go right

-- Files & undo
o.swapfile = false -- disable swapfile
o.undofile = true -- persistent undo across sessions

-- Clipboard
o.clipboard = "unnamedplus" -- use system clipboard

-- Mouse
o.mouse = "" -- disable mouse

