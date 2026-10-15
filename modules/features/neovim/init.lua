-- cache compiled Lua modules; must run before any require
vim.loader.enable()

-- nvim-pack-lock.json pins plugins; from the read-only store vim.pack uses a writable copy, resynced when it changes
local config_dir = vim.fn.stdpath("config")
local resync = false

local function read(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local data = f:read("a")
  f:close()
  return data
end

local function write(path, data)
  local f = assert(io.open(path, "w"))
  f:write(data)
  f:close()
end

local pack_add = vim.pack.add
local function add(specs, opts)
  return pack_add(specs, vim.tbl_extend("force", { confirm = false }, opts or {}))
end

if vim.uv.fs_access(config_dir, "W") then
  vim.pack.add = add
else
  local writable_config = vim.fs.joinpath(vim.fn.stdpath("data"), "nvim-pack-config")
  local committed = read(vim.fs.joinpath(config_dir, "nvim-pack-lock.json"))
  local seeded_path = vim.fs.joinpath(writable_config, "seeded-lock.json")
  if committed and committed ~= read(seeded_path) then
    vim.fn.mkdir(writable_config, "p")
    write(vim.fs.joinpath(writable_config, "nvim-pack-lock.json"), committed)
    write(seeded_path, committed)
    resync = true
  end

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

  vim.pack.add = with_writable_config(add)
  vim.pack.update = with_writable_config(vim.pack.update)
  vim.pack.del = with_writable_config(vim.pack.del)
end

require("config")
require("plugins")

-- move installed plugins to a newly committed lockfile's revisions
if resync then
  vim.pack.update(nil, { target = "lockfile", force = true })
end

local stale = vim.iter(vim.pack.get(nil, { info = false }))
    :filter(function(p) return not p.active end)
    :map(function(p) return p.spec.name end)
    :totable()
if #stale > 0 then
  vim.pack.del(stale)
end
