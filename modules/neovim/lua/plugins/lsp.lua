return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "b0o/schemastore.nvim" },
    config = function()
      local lsps = {
        lua_ls = { settings = { Lua = { workspace = { library = vim.api.nvim_get_runtime_file("", true) } } } },
        yamlls = {
          settings = {
            yaml = {
              format = { enable = false },
              schemaStore = { enable = false, url = "" },
              schemas = require('schemastore').yaml.schemas(),
            },
          }
        },
        nixd = true, -- NIX LSP
        tsserver = true, -- TypeScript/JavaScript LSP
        html = true, -- HTML LSP
        cssls = true, -- CSS/SCSS/Less LSP
        marksman = true, -- Markdown LSP
        jsonls = true, -- JSON LSP
        tofu_ls = true, -- Terraform LSP
      }

      for name, cfg in pairs(lsps) do
        if type(cfg) == "table" and next(cfg) ~= nil then
          vim.lsp.config(name, cfg)
        end
      end

      vim.lsp.enable(vim.tbl_keys(lsps))
    end
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        nix = { "nixfmt" },
        ansible = { "ansible-lint" },
      },
      format_on_save = {}, -- enables autocmd
    },
    config = function(_, opts)
      require("conform").setup(opts)
      require("conform").formatters.nixfmt = { append_args = { "--width", "6900" } }
    end,
  },
}
