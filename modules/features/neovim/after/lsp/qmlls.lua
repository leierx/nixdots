---@type vim.lsp.Config
return {
  -- -E reads QML_IMPORT_PATH; quickshell also writes a .qmlls.ini next to shell.qml
  cmd = { "qmlls", "-E" },
  filetypes = { "qml", "qmljs" },
  root_markers = { ".qmlls.ini", "shell.qml", ".git" },
}
