-- must run before any require
vim.loader.enable()

-- nvim-pack-lock.json pins plugins; from the read-only store vim.pack uses a writable copy, resynced when it changes
local config_dir = vim.fn.stdpath("config")
local resync = false
local seeded_path, committed

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
  committed = read(vim.fs.joinpath(config_dir, "nvim-pack-lock.json"))
  seeded_path = vim.fs.joinpath(writable_config, "seeded-lock.json")
  if committed and committed ~= read(seeded_path) then
    vim.fn.mkdir(writable_config, "p")
    write(vim.fs.joinpath(writable_config, "nvim-pack-lock.json"), committed)
    resync = true
  end

  -- only vim.pack's own calls: update's confirm buffer writes the lockfile long after update() returns
  local orig_stdpath = vim.fn.stdpath
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.fn.stdpath = function(what)
    if what == "config" and debug.getinfo(2, "S").source:find("vim/pack%.lua$") then
      return writable_config
    end
    return orig_stdpath(what)
  end

  vim.pack.add = add
end

require("config")
require("plugins")

if resync then
  vim.pack.update(nil, { target = "lockfile", force = true })
  -- seeded only once every plugin is on it, so an update that failed (offline, say) runs again next start
  local revs = vim.json.decode(committed).plugins
  local synced = vim.iter(vim.pack.get(nil, { info = false })):all(function(p)
    local head = vim.system({ "git", "rev-parse", "HEAD" }, { cwd = p.path, text = true }):wait().stdout
    return not revs[p.spec.name] or revs[p.spec.name].rev == vim.trim(head or "")
  end)
  if synced then
    write(seeded_path, committed)
  end
end

local stale = vim.iter(vim.pack.get(nil, { info = false }))
    :filter(function(p) return not p.active end)
    :map(function(p) return p.spec.name end)
    :totable()
if #stale > 0 then
  vim.pack.del(stale)
end
