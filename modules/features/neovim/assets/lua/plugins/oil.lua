vim.pack.add({
  "https://github.com/stevearc/oil.nvim",
  "https://github.com/malewicz1337/oil-git.nvim",
})

require("oil").setup({
  skip_confirm_for_simple_edits = true,
  use_default_keymaps = false,
  float = { preview_split = "right" },
  keymaps = {
    ["-"] = { "actions.parent", mode = "n" },
    ["<C-p>"] = { "actions.preview", opts = { split = "belowright" } },
    ["<CR>"] = "actions.select",
    ["<Esc>"] = { "actions.close", mode = "n" },
    ["_"] = { "actions.open_cwd", mode = "n" },
    ["g."] = { "actions.toggle_hidden", mode = "n" },
    ["g?"] = { "actions.show_help", mode = "n" },
    ["g\\"] = { "actions.toggle_trash", mode = "n" },
  },
  win_options = {
    signcolumn = "yes:2",
  },
  view_options = {
    show_hidden = true,
  },
  watch_for_changes = true,
})

require("oil-git").setup({
  show_file_highlights = true,
  show_directory_highlights = true,
  show_ignored_files = false,
})

-- Open the preview when oil is entered from a file, but respect a manual close
-- while browsing within oil.
local oil_aug = vim.api.nvim_create_augroup("OilAutoPreview", {})
vim.api.nvim_create_autocmd("BufLeave", {
  group = oil_aug,
  callback = function()
    if not require("oil.util").is_oil_bufnr(0) then
      vim.w.oil_want_preview = true
    end
  end,
})
vim.api.nvim_create_autocmd("BufEnter", {
  group = oil_aug,
  callback = function()
    if vim.bo.filetype ~= "oil" or not vim.w.oil_want_preview then
      return
    end
    vim.w.oil_want_preview = false
    require("oil.util").run_after_load(0, function()
      if require("oil").get_cursor_entry() and not require("oil.util").get_preview_win() then
        require("oil").open_preview()
      end
    end)
  end,
})
