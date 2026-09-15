vim.pack.add({
  { src = "https://github.com/rafamadriz/friendly-snippets" },
  { src = "https://github.com/saghen/blink.cmp",            version = vim.version.range("1.*") },
})

-- Path items carry a real filesystem name; everything else is an LSP kind.
-- mini.icons matches "file" on the basename's extension, so the label suffices.
local function icon_args(ctx)
  if ctx.source_name ~= "Path" then return "lsp", ctx.kind end
  return ctx.kind == "Folder" and "directory" or "file", ctx.label
end

require("blink.cmp").setup({
  -- 'default' = <C-y> accept, <C-n>/<C-p> cycle, <C-space> menu/docs, <C-k>
  keymap = { preset = "enter" },

  -- Native vim.snippet expansion; friendly-snippets is picked up automatically.
  snippets = { preset = "default" },

  completion = {
    menu = {
      border = "rounded",
      draw = {
        components = {
          kind_icon = {
            text = function(ctx)
              local icon = MiniIcons.get(icon_args(ctx))
              return (icon or ctx.kind_icon) .. ctx.icon_gap
            end,
            highlight = function(ctx)
              local _, hl = MiniIcons.get(icon_args(ctx))
              return hl or ctx.kind_hl
            end,
          },
        },
      },
    },
    documentation = { auto_show = true, auto_show_delay_ms = 200, window = { border = "rounded" } },

    ghost_text = { enabled = true },
  },

  signature = { enabled = true, window = { border = "rounded" } },

  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },

  fuzzy = { implementation = "prefer_rust" },
})
