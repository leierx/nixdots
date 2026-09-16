-- Full nvim-surround option surface, mirroring the plugin's v4 defaults.
-- `setup()` is additive, so any block below can be deleted to fall back to
-- the upstream default for that key.
--
-- Disable the plugin's default keymaps (ys/ds/cs/S/...) before it loads so we
-- can use the mini.surround-style `sa` / `sd` / `sr` mappings instead.
vim.g.nvim_surround_no_mappings = true

vim.pack.add({ "https://github.com/kylechui/nvim-surround" })

local config = require("nvim-surround.config")

require("nvim-surround").setup({
  surrounds = {
    ["("] = {
      add = { "( ", " )" },
      find = function() return config.get_selection({ motion = "a(" }) end,
      delete = "^(. ?)().-( ?.)()$",
      label = "( ... )",
    },
    [")"] = {
      add = { "(", ")" },
      find = function() return config.get_selection({ motion = "a)" }) end,
      delete = "^(.)().-(.)()$",
      label = "(...)",
    },
    ["{"] = {
      add = { "{ ", " }" },
      find = function() return config.get_selection({ motion = "a{" }) end,
      delete = "^(. ?)().-( ?.)()$",
      label = "{ ... }",
    },
    ["}"] = {
      add = { "{", "}" },
      find = function() return config.get_selection({ motion = "a}" }) end,
      delete = "^(.)().-(.)()$",
      label = "{...}",
    },
    ["<"] = {
      add = { "< ", " >" },
      find = function() return config.get_selection({ motion = "a<" }) end,
      delete = "^(. ?)().-( ?.)()$",
      label = "< ... >",
    },
    [">"] = {
      add = { "<", ">" },
      find = function() return config.get_selection({ motion = "a>" }) end,
      delete = "^(.)().-(.)()$",
      label = "<...>",
    },
    ["["] = {
      add = { "[ ", " ]" },
      find = function() return config.get_selection({ motion = "a[" }) end,
      delete = "^(. ?)().-( ?.)()$",
      label = "[ ... ]",
    },
    ["]"] = {
      add = { "[", "]" },
      find = function() return config.get_selection({ motion = "a]" }) end,
      delete = "^(.)().-(.)()$",
      label = "[...]",
    },
    ["'"] = {
      add = { "'", "'" },
      find = function() return config.get_selection({ motion = "a'" }) end,
      delete = "^(.)().-(.)()$",
      label = "'...'",
    },
    ['"'] = {
      add = { '"', '"' },
      find = function() return config.get_selection({ motion = 'a"' }) end,
      delete = "^(.)().-(.)()$",
      label = '"..."',
    },
    ["`"] = {
      add = { "`", "`" },
      find = function() return config.get_selection({ motion = "a`" }) end,
      delete = "^(.)().-(.)()$",
      label = "`...`",
    },
    ["i"] = { -- custom delimiters entered at runtime
      add = function()
        local left_delimiter = config.get_input("Enter the left delimiter: ")
        local right_delimiter = left_delimiter and config.get_input("Enter the right delimiter: ")
        if right_delimiter then
          return { { left_delimiter }, { right_delimiter } }
        end
      end,
      find = function() end,
      delete = function() end,
      label = "?...?",
    },
    ["t"] = {
      add = function()
        local user_input = config.get_input("Enter the HTML tag: ")
        if user_input then
          local element = user_input:match("^<?([^%s>]*)")
          local attributes = user_input:match("^<?[^%s>]*%s+(.-)>?$")
          local open = attributes and element .. " " .. attributes or element
          local close = element
          return { { "<" .. open .. ">" }, { "</" .. close .. ">" } }
        end
      end,
      find = function() return config.get_selection({ motion = "at" }) end,
      delete = "^(%b<>)().-(%b<>)()$",
      change = {
        target = "^<([^%s<>]*)().-([^/]*)()>$",
        replacement = function()
          local user_input = config.get_input("Enter the HTML tag: ")
          if user_input then
            local element = user_input:match("^<?([^%s>]*)")
            local attributes = user_input:match("^<?[^%s>]*%s+(.-)>?$")
            local open = attributes and element .. " " .. attributes or element
            local close = element
            return { { open }, { close } }
          end
        end,
      },
      label = "<tag>...</tag>",
    },
    ["T"] = {
      add = function()
        local user_input = config.get_input("Enter the HTML tag: ")
        if user_input then
          local element = user_input:match("^<?([^%s>]*)")
          local attributes = user_input:match("^<?[^%s>]*%s+(.-)>?$")
          local open = attributes and element .. " " .. attributes or element
          local close = element
          return { { "<" .. open .. ">" }, { "</" .. close .. ">" } }
        end
      end,
      find = function() return config.get_selection({ motion = "at" }) end,
      delete = "^(%b<>)().-(%b<>)()$",
      change = {
        target = "^<([^>]*)().-([^/]*)()>$",
        replacement = function()
          local user_input = config.get_input("Enter the HTML tag: ")
          if user_input then
            local element = user_input:match("^<?([^%s>]*)")
            local attributes = user_input:match("^<?[^%s>]*%s+(.-)>?$")
            local open = attributes and element .. " " .. attributes or element
            local close = element
            return { { open }, { close } }
          end
        end,
      },
      label = "<tag>...</tag>",
    },
    ["f"] = {
      add = function()
        local result = config.get_input("Enter the function name: ")
        if result then
          return { { result .. "(" }, { ")" } }
        end
      end,
      find = function()
        local selection = config.get_selection({
          query = { capture = "@call.outer", type = "textobjects" },
        })
        -- prefer tree-sitter selections when available, else fall back to a pattern
        if selection then
          return selection
        end
        return config.get_selection({ pattern = "[^=%s%(%){}]+%b()" })
      end,
      delete = "^(.-%()().-(%))()$",
      change = {
        target = "^.-([%w_]+)()%(.-%)()()$",
        replacement = function()
          local result = config.get_input("Enter the function name: ")
          if result then
            return { { result }, { "" } }
          end
        end,
      },
      label = "function(...)",
    },
    invalid_key_behavior = {
      add = function(char)
        if not char or char:find("%c") then
          return nil
        end
        return { { char }, { char } }
      end,
      find = function(char)
        if not char or char:find("%c") then
          return nil
        end
        return config.get_selection({ pattern = vim.pesc(char) .. ".-" .. vim.pesc(char) })
      end,
      delete = function(char)
        if not char then
          return nil
        end
        return config.get_selections({ char = char, pattern = "^(.)().-(.)()$" })
      end,
    },
  },
  aliases = {
    ["a"] = ">",
    ["b"] = ")",
    ["B"] = "}",
    ["r"] = "]",
    ["q"] = { '"', "'", "`" },
    ["s"] = { "}", "]", ")", ">", '"', "'", "`" },
  },
  highlight = {
    duration = 0,
  },
  move_cursor = "begin",
  indent_lines = function(start, stop)
    local b = vim.bo
    -- only re-indent when the buffer already has an indent method configured
    if start < stop and (b.equalprg ~= "" or b.indentexpr ~= "" or b.cindent or b.smartindent or b.lisp) then
      vim.cmd(string.format("silent normal! %dG=%dG", start, stop))
      require("nvim-surround.cache").set_callback("")
    end
  end,
})

-- mini.surround-style keymaps
vim.keymap.set("n", "sa", "<Plug>(nvim-surround-normal)", { desc = "Add surrounding" })
vim.keymap.set("x", "sa", "<Plug>(nvim-surround-visual)", { desc = "Add surrounding" })
vim.keymap.set("n", "sd", "<Plug>(nvim-surround-delete)", { desc = "Delete surrounding" })
vim.keymap.set("n", "sr", "<Plug>(nvim-surround-change)", { desc = "Replace surrounding" })
