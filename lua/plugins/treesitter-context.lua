-- =============================================================================
-- treesitter-context.lua · sticky current function/class at the top of the
-- window (§3). Uses the treesitter parsers already installed by
-- plugins/treesitter.lua — no extra parser downloads.
--
-- Why this over a hand-rolled winbar/nvim-navic solution: nvim-navic needs
-- LSP documentSymbol support per-server (inconsistent across your servers,
-- e.g. emmet_ls/tailwindcss don't provide it), while treesitter-context
-- works off the same parsers already driving highlighting/folding for
-- every language in plugins/treesitter.lua — one less moving part, and it
-- degrades gracefully (nothing shown) rather than erroring when a server
-- lacks symbol support.
-- =============================================================================
return {
  "nvim-treesitter/nvim-treesitter-context",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    enable = true,
    max_lines = 3,          -- cap so a deeply nested scope doesn't eat the window
    min_window_height = 12, -- don't bother in small splits
    line_numbers = true,
    multiline_threshold = 1,
    trim_scope = "outer",
    mode = "cursor",
    separator = nil,        -- no extra line, keeps it visually quiet
  },
  config = function(_, opts)
    require("treesitter-context").setup(opts)
    vim.keymap.set("n", "<leader>tc", "<CMD>TSContextToggle<CR>", { desc = "[T]oggle sticky [C]ontext" })
    vim.keymap.set("n", "[c", function()
      require("treesitter-context").go_to_context(vim.v.count1)
    end, { silent = true, desc = "Jump to sticky context" })
  end,
}
