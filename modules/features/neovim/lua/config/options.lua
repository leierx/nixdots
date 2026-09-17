local o = vim.opt

-- Editing
o.expandtab = true -- insert spaces instead of literal tabs
o.shiftwidth = 2 -- indent size for << and >>, autoindent, etc.
o.softtabstop = 2 -- <Tab>/<BS> behave like 2-space indent steps
o.tabstop = 2 -- visual width of a tab character

-- Wrapping
o.linebreak = true -- wrap at word boundaries (not mid-word)
o.showbreak = "↳ " -- prefix for wrapped lines
o.breakindent = true -- keep indentation on wrapped lines
o.breakindentopt = "shift:2" -- extra indent for wrapped lines

-- Line numbers & scrolling
o.number = true
o.relativenumber = true
o.scrolloff = 4 -- keep a little context above/below the cursor
o.smoothscroll = true -- scroll wrapped lines by screen line

-- Search
o.ignorecase = true -- case-insensitive search...
o.smartcase = true -- ...unless the pattern contains uppercase

-- UI
o.termguicolors = true -- 24-bit colors
o.laststatus = 3 -- global statusline
o.winborder = "rounded" -- default border for floating windows
o.list = true -- show tabs, trailing spaces, nbsp (default listchars)
o.updatetime = 250 -- faster CursorHold for diagnostics, gitsigns, etc.

-- Splits
o.splitbelow = true -- new horizontal splits go below
o.splitright = true -- new vertical splits go right

-- Files & undo
o.swapfile = false -- disable swapfile
o.undofile = true -- persistent undo across sessions
o.confirm = true -- ask to save instead of erroring on :q

-- Input
o.mouse = "" -- disable mouse

vim.schedule(function()
  o.clipboard = "unnamedplus" -- system clipboard (deferred for startup speed)
end)

-- Messages & cmdline (ui2)
o.cmdheight = 0

require("vim._core.ui2").enable({
  enable = true,
  msg = {
    targets = "msg", -- floating message window (bottom right)
    cmd = { height = 0.5 },
    dialog = { height = 0.5 },
    msg = { height = 0.5, timeout = 4000 },
    pager = { height = 0.5 },
  },
})
