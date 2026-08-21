-- =============================================================================
-- indent-blankline.lua · Neovim 0.13+
-- Visual indent guides — scoped to Python only
-- =============================================================================

return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    ft = { "python" },
    config = function()
        require("ibl").setup({
            indent = {
                char = "│",
                tab_char = "│",
            },
            scope = {
                enabled = true,
                show_start = true,
                show_end = false,
                char = "▏",
            },
            exclude = {
                filetypes = { "help", "dashboard", "NvimTree", "lazy", "mason" },
            },
        })

        vim.api.nvim_set_hl(0, "IblIndent", { fg = "#3b3b3b" })
        vim.api.nvim_set_hl(0, "IblScope",  { fg = "#00BFFF", bold = true })
    end,
}
