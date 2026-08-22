-- =============================================================================
-- plugins/statusline.lua · lualine.nvim
--
-- Replaces Neovim's bare default statusline (which just prints the raw
-- buffer path/name with no truncation, no modified marker, no icon) with a
-- readable one: mode, git branch, diagnostics count, a nicely-shortened
-- relative filename with a filetype icon, then position/progress.
-- =============================================================================
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("lualine").setup({
      options = {
        theme = "dracula", -- matches plugins/colorscheme.lua
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
        -- globalstatus was OFF for a reason: with laststatus=3 (one shared
        -- statusline for the whole editor), Neovim's built-in incsearch
        -- match-count indicator ("[1/12]" while typing /pattern) has no
        -- per-window statusline left to draw into, and it just silently
        -- disappears. That's what broke it -- not your search settings.
        -- Keeping this false restores the native match-count display.
        -- globalstatus = false,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" },
        lualine_c = {
          {
            -- Diagnostics count for the current buffer, right where you're
            -- looking, colored by severity.
            "diagnostics",
            sources = { "nvim_diagnostic" },
            symbols = { error = " ", warn = " ", info = " ", hint = "󰠠 " },
          },
          {
            -- The filename component itself. path = 1 -> relative path from
            -- cwd (e.g. "lua/configs/lsp.lua") instead of the bare
            -- filename or a full absolute path -- easiest to scan, and
            -- lualine truncates this itself when the window gets narrow
            -- instead of wrapping or pushing other sections off-screen.
            "filename",
            path = 1,
            symbols = { modified = " ●", readonly = " 󰌾", unnamed = "[No Name]" },
          },
        },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "location" },
      },
    })
  end,
}
