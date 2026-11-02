-- cache compiled Lua modules; must run before any require
vim.loader.enable()

-- nvim-pack-lock.json pins plugins; from the read-only store vim.pack uses a writable copy, resynced when it changes
local config_dir = vim.fn.stdpath("config")
-- set when the committed lockfile changed: { lock = its contents, seeded = where to record it once synced }
local resync

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
    resync = { lock = committed, seeded = seeded_path }
  end

  local orig_stdpath = vim.fn.stdpath
  local function writable_stdpath(what)
    if what == "config" then
      return writable_config
    end
    return orig_stdpath(what)
  end
  -- vim.pack calls its own (wrapped) functions, and update's confirm buffer writes the
  -- lockfile on :write, so restore only once the outermost call and that buffer are done
  local depth, confirm_pending = 0, false
  local function restore()
    if depth == 0 and not confirm_pending then
      vim.fn.stdpath = orig_stdpath
    end
  end
  local function with_writable_config(fn)
    return function(...)
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.fn.stdpath = writable_stdpath
      depth = depth + 1
      local ok, result = pcall(fn, ...)
      depth = depth - 1
      local buf = vim.api.nvim_get_current_buf()
      if not confirm_pending and vim.api.nvim_buf_get_name(buf):match("^nvim%-pack://confirm#") then
        confirm_pending = true
        vim.api.nvim_create_autocmd("BufDelete", {
          buffer = buf,
          once = true,
          callback = function()
            confirm_pending = false
            restore()
          end,
        })
      end
      restore()
      if not ok then
        error(result)
      end
      return result
    end
  end

  vim.pack.add = with_writable_config(add)
  vim.pack.update = with_writable_config(vim.pack.update)
  vim.pack.del = with_writable_config(vim.pack.del)
  vim.pack.get = with_writable_config(vim.pack.get)
end

require("config")
require("plugins")

-- move installed plugins to a newly committed lockfile's revisions
if resync then
  vim.pack.update(nil, { target = "lockfile", force = true })
  -- mark it seeded only once every plugin got there, so a failed sync (offline) retries next start
  local pinned = vim.json.decode(resync.lock).plugins
  local synced = vim.iter(vim.pack.get(nil, { info = false })):all(function(p)
    local lock = pinned[p.spec.name]
    return not (p.active and lock)
      or vim.trim(vim.fn.system({ "git", "-C", p.path, "rev-parse", "HEAD" })) == lock.rev
  end)
  if synced then
    write(resync.seeded, resync.lock)
  end
end

local stale = vim.iter(vim.pack.get(nil, { info = false }))
    :filter(function(p) return not p.active end)
    :map(function(p) return p.spec.name end)
    :totable()
if #stale > 0 then
  vim.pack.del(stale)
end
