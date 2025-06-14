return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")

      -- PHP LSP: intelephense
      lspconfig.intelephense.setup({})

      -- HTML LSP: also works inside PHP files
      lspconfig.html.setup({
        filetypes = { "html", "php" },
      })
    end,
  },
}

