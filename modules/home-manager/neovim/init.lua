-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  lockfile = vim.fn.stdpath("cache") .. "/lazy-lock.json",
  change_detection = { enabled = false },
  spec = {{ import = "plugins" }}, -- import plugins from plugins folder
  readme = { enabled = false, },

  checker = {
    enabled = true,
    concurrency = 1, -- slow and steady
  },

  install = {
    missing = true,
    colorscheme = { "kanagawa", "habamax" },
  },

  ui = {
    border = "rounded",
    title = "Lazy",
  },
})

require("config")
