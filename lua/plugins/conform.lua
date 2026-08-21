-- Replaces none-ls/null-ls entirely (unmaintained, heavier, needed a
-- plenary dependency) for every language, including the goimports/gofumpt
-- pair that used to live inside go-lsp.lua.
return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff_organize_imports", "ruff_format" },
      go = { "goimports", "gofumpt" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      json = { "prettier" },
      -- jsonc = { "prettier" },
      markdown = { "prettier" },
      java = { "prettier" },
    },
    formatters = {
      prettier = { prefer_local = "node_modules/.bin" },
      goimports = { args = { "-local", "" } }, -- set your module prefix if needed
    },
    -- Format-on-save is OFF on purpose -- Vijay: manual formatting only.
    -- Trigger it yourself with <leader>cf (mapped in configs/lsp.lua) or
    -- :ConformInfo / :lua require("conform").format({ async = true }).
    -- To go back to auto-format-on-save, uncomment this:
    --
    -- format_on_save = function(bufnr)
    --   if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
    --   return { timeout_ms = 2000, lsp_format = "fallback" }
    -- end,
  },
}
