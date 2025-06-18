return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- PHP LSP: Intelephense (via global npm)
        intelephense = {
          cmd = { "intelephense", "--stdio" },
          filetypes = { "php" },
          root_dir = require("lspconfig.util").root_pattern("composer.json", ".git"),
          settings = {
            intelephense = {
              files = {
                maxSize = 5000000,
              },
            },
          },
        },

        -- HTML LSP support
        html = {
          filetypes = { "html", "php" },
        },

        -- Optional: Emmet for fast HTML/CSS-like editing
        emmet_ls = {
          filetypes = { "html", "php", "css", "javascriptreact", "typescriptreact" },
          init_options = {
            html = {
              options = {
                ["bem.enabled"] = true,
              },
            },
          },
        },
      },
    },
  },
}

