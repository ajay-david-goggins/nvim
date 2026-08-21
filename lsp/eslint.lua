---@type vim.lsp.Config
return {
  settings = {
    codeActionOnSave = { enable = true, mode = "all" },
  },
  -- NOTE: publishDiagnostics is NOT overridden here -- see lsp/ts_ls.lua for
  -- why. configs/lsp.lua's single global handler already covers this client.
}
