---@type vim.lsp.Config
return {
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
        unusedvariable = true,
        shadow = true,
        nilness = true,
        useany = true,
      },
      staticcheck = true,
      gofumpt = true,
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
      codelenses = {
        gc_details = true,
        generate = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },
      usePlaceholders = true,
      completeUnimported = true,
      matcher = "Fuzzy",
      semanticTokens = true,
      directoryFilters = { "-.git", "-.vscode", "-.idea", "-node_modules", "-vendor" },
    },
  },
}
