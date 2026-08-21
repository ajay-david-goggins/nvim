-- Thin on purpose: nvim-lspconfig now only supplies default per-server data
-- (cmd, filetypes, root markers). Our overrides in nvim/lsp/<name>.lua are
-- merged on top automatically by Neovim core — see :h lsp-config.
return {
  "neovim/nvim-lspconfig",
  lazy = false,
  priority = 900, -- load before FileType fires so lsp/*.lua configs exist
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    require("configs.lsp")
  end,
}
