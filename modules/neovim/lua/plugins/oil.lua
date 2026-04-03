return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
    watch_for_changes = true,
    use_default_keymaps = false,
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
    float = { preview_split = "right" },
  },
  keys = { { "<leader>e", function() require("oil").open() end } },
}
