local treesitter_parsers = {
  "bash", "c", "diff", "css", "scss",
  "html", "javascript", "jsdoc", "json", "jsonc",
  "lua", "luadoc", "luap", "markdown", "markdown_inline",
  "query", "regex", "toml", "tsx", "typescript",
  "xml", "yaml", "nix",
}

local mason_language_servers = {
  "bashls", -- bash-language-server
  "clangd", -- C / C++ (covers `c` + `diff`)
  "cssls", -- css-lsp (CSS + SCSS)
  "html", -- html-lsp
  "ts_ls", -- typescript-language-server (JS / TS / TSX / JSDoc)
  "jsonls", -- json-lsp (JSON / JSONC)
  "lua_ls", -- lua-language-server
  "marksman", -- Markdown
  "taplo", -- TOML
  "lemminx", -- XML
  "yamlls", -- yaml-language-server (Kubernetes schemas)
  "ansiblels", -- ansible-language-server (YAML/Ansible)
  -- "nil_ls", nil wont build unless nix binary is in path
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-context",
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    branch = 'master',
    lazy = false,
    build = ":TSUpdate",
    opts = {
      ensure_installed = treesitter_parsers,
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      indent = { enable = true },
    },

    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {{ "mason-org/mason.nvim", opts = {} }},
        enabled = vim.fn.executable("nix") == 0,
        opts = { ensure_installed = mason_language_servers },
      },
    },
    config = function()
      -- Only do manual setup when the `nix` binary exists
      if vim.fn.executable("nix") == 1 then
        local lspconfig = require("lspconfig")
        local language_servers = {}
        local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

        for _, name in ipairs(mason_language_servers) do
          language_servers[name] = { capabilities = capabilities }
        end

        language_servers.lua_ls.settings = { Lua = { diagnostics = { globals = { "vim" } } } }

        for name, opts in pairs(language_servers) do
          lspconfig[name].setup(opts)
        end
      end
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- LSP completions
      "hrsh7th/cmp-buffer", -- words in current / open buffers
      "hrsh7th/cmp-path", -- filesystem paths
      "saadparwaiz1/cmp_luasnip", -- bridge LuaSnip → cmp
      "L3MON4D3/LuaSnip", -- snippet engine
      "rafamadriz/friendly-snippets", -- community snippet collection
      "onsails/lspkind.nvim", -- icons in the completion menu
    },

    opts = function()
      require("luasnip.loaders.from_vscode").lazy_load()

      local cmp = require("cmp")
      local lspkind = require("lspkind")

      return {
        snippet = {
          expand = function(args) require("luasnip").lsp_expand(args.body) end,
        },

        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },

        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "…",
          }),
        },

        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping.confirm({ select = true }),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
        }),

        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      }
    end,

    config = function(_, opts) require("cmp").setup(opts) end,
  },
}
