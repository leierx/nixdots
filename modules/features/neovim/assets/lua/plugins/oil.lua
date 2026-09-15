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
