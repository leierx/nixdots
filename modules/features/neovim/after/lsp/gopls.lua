return {
  settings = {
    gopls = {
      -- match the conform.nvim formatters, so manual formatting agrees with save
      gofumpt = true,
      usePlaceholders = true,
      analyses = {
        nilness = true,
        shadow = true,
        unusedparams = true,
        unusedwrite = true,
        useany = true,
      },
      codelenses = {
        generate = true,
        regenerate_cgo = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
}
