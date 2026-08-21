-- =============================================================================
-- todo-comments.lua · TODO/FIXME/NOTE/WARN/HACK/PERF annotations (§4).
-- Subtle by design: only the keyword itself gets a color/icon, not the
-- whole line, and not the rest of the editor. Green/yellow bias per your
-- request — errors stay a distinct red so they don't blend with FIXME.
-- =============================================================================
return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    signs = true,
    sign_priority = 8,
    keywords = {
      FIX  = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
      TODO = { icon = " ", color = "info" },
      HACK = { icon = " ", color = "warning" },
      WARN = { icon = " ", color = "warning", alt = { "WARNING", "IMPORTANT" } },
      PERF = { icon = " ", color = "hint", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
      NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
    },
    colors = {
      error   = { "#f38ba8" },
      warning = { "#f9e2af" }, -- yellow
      info    = { "#89b4fa" },
      hint    = { "#7cfc00" }, -- green, matches the Comment highlight in options.lua
      default = { "#7cfc00" },
    },
    highlight = {
      multiline = false,       -- keep it to the annotated line, not the whole block
      before = "",
      keyword = "wide_bg",     -- only the keyword gets a background, not the message
      after = "fg",
    },
  },
  config = function(_, opts)
    require("todo-comments").setup(opts)

    local map = vim.keymap.set
    map("n", "]t", function() require("todo-comments").jump_next() end, { desc = "Next TODO/FIXME/NOTE" })
    map("n", "[t", function() require("todo-comments").jump_prev() end, { desc = "Prev TODO/FIXME/NOTE" })

    -- Slots into the global/project Search namespace from telescope.lua.
    map("n", "<leader>st", "<CMD>TodoTelescope<CR>", { desc = "[S]earch [T]odos (project)" })
  end,
}
