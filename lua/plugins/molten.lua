-- =============================================================================
-- lua/plugins/molten.lua
-- True Jupyter Notebook Engine for Neovim (Inline Output, ipykernel)
-- =============================================================================

return {
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    lazy = false,
    init = function()
      -- Don't pop up floating window on every execute; display inline virtual text instead (VS Code style)
      vim.g.molten_auto_open_output = false
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true

      -- Window sizing when explicitly inspecting output (<leader>jo)
      vim.g.molten_output_win_max_height = 22
      vim.g.molten_output_win_max_width = 100
      vim.g.molten_wrap_output = true
      vim.g.molten_output_crop_border = true
    end,
  },
}
