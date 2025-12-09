local function has_dirty_real_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr)
      and vim.bo[bufnr].buftype == ""
      and vim.fn.buflisted(bufnr) == 1
      and vim.bo[bufnr].modifiable
      and vim.bo[bufnr].modified
    then
        return true
    end
  end
  return false
end

local function commit_and_push()
  vim.cmd('G fetch origin')

  if has_dirty_real_buffers() then
    local ans = vim.fn.confirm(
      "Unsaved buffers – write them first?",
      "&Yes\n&No",
      1
    )

    if ans ~= 1 then
      vim.notify("Aborted: unsaved files", vim.log.levels.WARN)
      return
    end
    vim.cmd("wall")

    -- Sanity check
    if has_dirty_real_buffers() then
      vim.notify("Aborted: some buffers still dirty", vim.log.levels.ERROR)
      return
    end
  end

  vim.cmd('G add --all')

  vim.ui.input({ prompt = 'Commit message: ' }, function(msg)
    if not msg or msg == '' then
      vim.notify('Aborted: empty commit message', vim.log.levels.WARN)
      return
    end
    vim.cmd('G commit -m ' .. vim.fn.shellescape(msg))
    vim.cmd('G push')
  end)
end

return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "-" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
    };
  },
  {
    "tpope/vim-fugitive",
    init = function() -- expose helpers **before** keymaps.lua runs
      package.loaded["git.custom-functions"] = {
        commit_and_push = commit_and_push,
      }
    end,
  },
}
