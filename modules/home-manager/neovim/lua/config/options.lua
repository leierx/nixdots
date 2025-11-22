local o = vim.opt

-- Line numbers & gutters
o.number = true -- absolute line numbers
o.relativenumber = true -- relative (for motions)
o.signcolumn = "yes" -- always show diagnostics/Git column

-- Cursor & viewport
o.cursorline = true -- highlight current line
o.scrolloff = 6 -- keep 6 lines visible above/below
o.sidescrolloff = 8 -- keep 8 columns visible left/right

-- Split window behaviour
o.splitbelow = true -- :split opens below
o.splitright = true -- :vsplit opens to the right
o.winminwidth = 5 -- minimum window width before collapse

-- UI feedback & latency
o.cmdheight = 0 -- hide command line when idle (Neovim ≥0.10)
o.timeoutlen = 400 -- faster which-key popup timeout

-- Tabline, statusline & theme
o.laststatus = 3 -- global statusline

-- Invisible character rendering
o.list = true -- show invisible characters
o.listchars = { tab = "▸ ", trail = "·", extends = "›", precedes = "‹" }

-- Indentation & tab behaviour
o.expandtab = true -- insert spaces instead of tab characters
o.shiftwidth = 2 -- number of spaces for each indent level
o.tabstop = 2 -- display width of a tab character
o.softtabstop = 2 -- how <Tab> and <BS> behave in insert mode
o.smartindent = true -- auto-indent new lines based on syntax

-- Wrapping behaviour
o.wrap = false -- disable soft wrapping of lines
o.breakindent = true -- preserve indentation when wrapping
o.linebreak = true -- wrap lines only at convenient break points

-- Search behaviour
o.ignorecase = true -- ignore case in search...
o.smartcase = true -- ...unless uppercase letters are used
o.hlsearch = false -- highlight all matches after search
o.formatoptions:remove({ "c", "r", "o" }) -- don't insert the current comment leader automatically for auto-wrapping comments using 'textwidth', hitting <Enter> in insert mode, or hitting 'o' or 'O' in normal mode.

-- Mouse & Clipboard
o.mouse = "" -- enable mouse support in all modes
o.clipboard = "unnamedplus" -- use system clipboard for all yank/paste

-- Folding
o.foldmethod = "expr" -- folding controlled by expression
o.foldexpr = "nvim_treesitter#foldexpr()" -- Tree-sitter folding rules
o.foldenable = false -- don't fold anything by default
o.foldlevel = 99 -- allow all folds to be open

-- files & persistence
o.undofile = true -- enable persistent undo history
o.undodir = vim.fn.stdpath("data") .. "/undo" -- location for undo files
o.swapfile = false -- disable swap file creation

