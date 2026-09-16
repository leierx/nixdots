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

vim.lsp.config('*', {
  on_attach = function(client, bufnr)
    -- some clients support workspace diagnostics natively
    if client:supports_method("workspace/diagnostic", bufnr) then
      vim.lsp.buf.workspace_diagnostics({ client_id = client.id })
    else
      require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
    end
  end
})
