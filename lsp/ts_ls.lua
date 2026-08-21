local inlay_hints = {
  includeInlayParameterNameHints = "all",
  includeInlayFunctionParameterTypeHints = true,
  includeInlayVariableTypeHints = true,
  includeInlayPropertyDeclarationTypeHints = true,
  includeInlayFunctionLikeReturnTypeHints = true,
  includeInlayEnumMemberValueHints = true,
}

---@type vim.lsp.Config
return {
  settings = {
    typescript = { inlayHints = inlay_hints },
    javascript = { inlayHints = inlay_hints },
  },
  -- NOTE: publishDiagnostics is NOT overridden here. configs/lsp.lua already
  -- installs configs.diagnostics.handler as the ONE global handler for every
  -- client. Also setting it per-client here was a second registration layer
  -- of the exact same function -- harmless once the handler itself no
  -- longer recurses, but redundant and exactly the kind of double-wiring
  -- that caused the stack overflow in the first place, so it's removed.
  -- The implicit-`any` filtering still works globally; toggle with
  -- :ToggleAnyDiagnostics or <leader>dx.
}
