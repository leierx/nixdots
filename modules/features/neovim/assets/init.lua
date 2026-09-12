require("options")
require("keymap")
require("autocmd")
require("filetypes")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" }, { "\nPress any key to exit..." } }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup
require("lazy").setup({
  -- cachedir instead of ~/config/nvim
  lockfile = vim.fn.stdpath("cache") .. "/lazy-lock.json",
  -- makes it a little nicer
  ui = { border = "rounded" },
  install = { colorscheme = { "kanagawa", "habamax" } },
  -- less overhead
  change_detection = { enabled = false, notify = false },
  -- Plugins
  spec = { { import = "plugins" } },
  -- automagically check for updates, but dont notify me
  checker = { enabled = true, notify = false },
})

