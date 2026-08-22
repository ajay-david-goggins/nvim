-- =============================================================================
-- treesitter-context.lua · Neovim 0.13+ · Arch Linux · 2026
-- Sticky scroll: shows the enclosing function/class at top of window
-- =============================================================================

return {
    {
        "nvim-treesitter/nvim-treesitter-context",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            enable = true,
            max_lines = 3,          -- cap how many context lines stack up
            min_window_height = 20, -- don't bother on tiny splits
            line_numbers = true,
            trim_scope = "outer",   -- keep outermost def if multiple nest
            mode = "cursor",        -- context = what encloses the CURSOR, not just top of window
            separator = nil,
        },
        keys = {
            {
                "<leader>cx",
                function() require("treesitter-context").go_to_context() end,
                desc = "  Jump to Context (Enclosing Function)",
            },
        },
    },
}
