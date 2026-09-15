vim.pack.add({ "https://github.com/wansmer/treesj" })

-- Default keymaps (<leader>m/s/j) are off. Shift+J toggles the treesitter node
-- at the cursor (split when single-line, join when multi-line), replacing
-- Neovim's line-join; nodes treesj has no preset for just notify.
require("treesj").setup({ use_default_keymaps = false })

vim.keymap.set("n", "J", function() require("treesj").toggle() end, { desc = "Toggle split/join node" })
