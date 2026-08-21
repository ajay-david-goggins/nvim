---@type vim.lsp.Config
return {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic", -- "off" | "basic" | "strict"
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
        diagnosticSeverityOverrides = {
          reportMissingImports = "none",
          reportMissingTypeStubs = "none",
          reportUnusedImport = "warning",
          reportUnusedVariable = "warning",
          reportPrivateUsage = "none",
          reportAttributeAccessIssue = "warning",
        },
      },
    },
  },
}
