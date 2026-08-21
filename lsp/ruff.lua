---@type vim.lsp.Config
return {
  -- pyright owns hover/type-info; ruff only handles lint + fixes
  on_attach = function(client, _)
    client.server_capabilities.hoverProvider = false
  end,
  init_options = {
    settings = {
      lint = {
        ignore = { "E501", "F401" }, -- line-too-long, unused-import
      },
    },
  },
}
