---@type vim.lsp.Config
return {
  -- -E makes qmlls read QML_IMPORT_PATH; quickshell additionally writes a
  -- .qmlls.ini (with its importPaths) next to shell.qml on first launch.
  cmd = { "qmlls", "-E" },
  filetypes = { "qml", "qmljs" },
  root_markers = { ".qmlls.ini", "shell.qml", ".git" },
}
