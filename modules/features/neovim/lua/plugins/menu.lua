local M = {}

local function collapse_spaces()
  local view = vim.fn.winsaveview()
  -- keeppatterns: n and hlsearch stay on the last real search
  vim.cmd([[keeppatterns %s/\S\zs \{2,}/ /ge]])
  vim.fn.winrestview(view)
end

local function save_unformatted()
  vim.b.skip_format = true
  local ok, err = pcall(vim.cmd.write)
  vim.b.skip_format = nil
  if not ok then
    error(err, 0)
  end
end

local entries = {
  { "Collapse double spaces", collapse_spaces },
  { "Save without formatting", save_unformatted },
  { "Pack: update", function() vim.pack.update() end },
  { "Pack: sync to lockfile", function() vim.pack.update(nil, { target = "lockfile", force = true }) end },
  { "Treesitter: update parsers", function() vim.cmd("TSUpdate") end },
  { "All finders", function() require("fzf-lua").builtin() end },
}

function M.open()
  require("fzf-lua").fzf_exec(
    vim.tbl_map(function(e) return e[1] end, entries),
    {
      prompt = "Menu> ",
      winopts = { height = 0.4, width = 0.4, preview = { hidden = true } },
      actions = {
        default = function(selected)
          for _, e in ipairs(entries) do
            if e[1] == selected[1] then
              return e[2]()
            end
          end
        end,
      },
    }
  )
end

return M
