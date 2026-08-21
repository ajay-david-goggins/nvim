-- Core DAP client only. Adapters + configurations are per-language
-- (plugins/lang/*.lua); binaries are installed by mason-nvim-dap.lua.
return {
  "mfussenegger/nvim-dap",
  lazy = true,
}
