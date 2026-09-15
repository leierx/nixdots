-- ~/.config/nvim is a nix store symlink (read-only), but vim.pack writes its
-- lockfile to stdpath('config'). Redirect stdpath('config') to a writable
-- directory around every vim.pack call so add/update/del still work.
local writable_config = vim.fs.joinpath(vim.fn.stdpath("data"), "nvim-pack-config")
local orig_stdpath = vim.fn.stdpath

local function with_writable_config(fn)
  return function(...)
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.stdpath = function(what)
      if what == "config" then
        return writable_config
      end
      return orig_stdpath(what)
    end
    local ok, result = pcall(fn, ...)
    vim.fn.stdpath = orig_stdpath
    if not ok then
      error(result)
    end
    return result
  end
end

vim.pack.add = with_writable_config(vim.pack.add)
vim.pack.update = with_writable_config(vim.pack.update)
vim.pack.del = with_writable_config(vim.pack.del)

local stale = vim.iter(vim.pack.get())
    :filter(function(p) return not p.active end)
    :map(function(p) return p.spec.name end)
    :totable()
if #stale > 0 then
  vim.pack.del(stale)
end

require("config")
require("plugins")
