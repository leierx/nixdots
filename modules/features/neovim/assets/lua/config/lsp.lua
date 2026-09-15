vim.pack.add({
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/b0o/SchemaStore.nvim",
  "https://github.com/artemave/workspace-diagnostics.nvim",
})

local servers = {
  "lua_ls",
  "nixd",
  "ts_ls",
  "html",
  "cssls",
  "marksman",
  "jsonls",
  "yamlls",
  "tofu_ls",
}

for _, name in ipairs(servers) do
  local path = vim.fs.joinpath(vim.fn.stdpath("config"), "lsp", name .. ".lua")
  if vim.uv.fs_stat(path) then
    vim.lsp.config(name, dofile(path))
  end
end

vim.lsp.enable(servers)
vim.lsp.inlay_hint.enable(true)

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "Request workspace-wide diagnostics once per client",
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    -- Clients without filetypes are in-process auxiliaries with nothing to
    -- diagnose.
    if not client or client.config.filetypes == nil or client._workspace_diag_set then
      return
    end
    client._workspace_diag_set = true
    if client:supports_method("workspace/diagnostic", args.buf) then
      vim.lsp.buf.workspace_diagnostics({ client_id = client.id })
    else
      require("workspace-diagnostics").populate_workspace_diagnostics(client, args.buf)
    end
  end,
})
