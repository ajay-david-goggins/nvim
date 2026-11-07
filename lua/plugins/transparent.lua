return {
    "xiyaowong/transparent.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        local transparent = require("transparent")
        local cache_file = vim.fn.stdpath("data") .. "/transparent_cache"
        if vim.fn.filereadable(cache_file) == 0 then
            vim.g.transparent_enabled = false
        end

        transparent.setup({
            extra_groups = {
                "NormalFloat",
                "FloatBorder",
                "FloatTitle",
                "NvimTreeNormal",
                "NvimTreeNormalNC",
                "NvimTreeWinSeparator",
                "NvimTreeEndOfBuffer",
                "TelescopeNormal",
                "TelescopeBorder",
                "TelescopePromptNormal",
                "TelescopePromptBorder",
                "TelescopeResultsNormal",
                "TelescopeResultsBorder",
                "TelescopePreviewNormal",
                "TelescopePreviewBorder",
                "WhichKeyFloat",
                "LineNrAbove",
                "LineNrBelow",
                "Folded",
                "SignColumnSB",
            },
            exclude_groups = {
                "CursorLine",
            },
        })

        -- Clear dynamic highlight groups by prefix
        transparent.clear_prefix("NvimTree")
        transparent.clear_prefix("Telescope")

        if vim.g.transparent_enabled then
            transparent.clear()
        end
    end,
}
