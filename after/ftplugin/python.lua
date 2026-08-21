-- =============================================================================
-- after/ftplugin/python.lua · Neovim 0.13+
-- Python-specific indent rules — treesitter drives indent, not smartindent
-- =============================================================================

vim.opt_local.smartindent = false
vim.opt_local.autoindent  = true
vim.opt_local.expandtab   = false
vim.opt_local.shiftwidth  = 4
vim.opt_local.tabstop     = 4
vim.opt_local.softtabstop = 4

-- Force Neovim core's treesitter-based indent (works regardless of
-- nvim-treesitter plugin version/branch)
vim.opt_local.indentexpr = "v:lua.vim.treesitter.indentexpr()"

print(".... work file")
