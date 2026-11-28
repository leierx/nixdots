-- overrides live in after/lsp/<name>.lua, which wins over nvim-lspconfig's lsp/
vim.lsp.enable({
  "lua_ls",
  "nixd",
  "qmlls",
  "ts_ls",
  "html",
  "cssls",
  "marksman",
  "jsonls",
  "yamlls",
  "tofu_ls",
  "gopls",
})

-- registered before conform's format_on_save, so gofumpt formats the result
vim.api.nvim_create_autocmd("BufWritePre", {
  desc = "Organize Go imports",
  pattern = "*.go",
  callback = function(args)
    if vim.b[args.buf].skip_format then
      return
    end
    local client = vim.lsp.get_clients({ bufnr = args.buf, name = "gopls" })[1]
    if not client then
      return
    end
    local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
    params.context = { only = { "source.organizeImports" }, diagnostics = {} }
    local response = client:request_sync("textDocument/codeAction", params, 1000, args.buf)
    for _, action in ipairs(response and response.result or {}) do
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
      end
    end
  end,
})

-- LspAttach, not on_attach: a server's own on_attach (ts_ls) would replace ours
local populated = {}
vim.api.nvim_create_autocmd("LspAttach", {
  desc = "Workspace diagnostics",
  callback = function(args)
    if populated[args.data.client_id] then
      return
    end
    populated[args.data.client_id] = true
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if client:supports_method("workspace/diagnostic", args.buf) then
      vim.lsp.buf.workspace_diagnostics({ client_id = client.id })
    end
  end,
})
