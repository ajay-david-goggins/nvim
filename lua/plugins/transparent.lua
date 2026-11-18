return {
    "xiyaowong/transparent.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        local transparent = require("transparent")
        local cache_file = vim.fn.stdpath("data") .. "/transparent_cache"
        if vim.fn.filereadable(cache_file) == 0 then
            vim.g.transparent_enabled = true
        end

        transparent.setup({
            extra_groups = {
                -- Floating Popups & Windows
                "NormalFloat",
                "NormalFloatNC",
                "FloatBorder",
                "FloatTitle",
                "FloatFooter",
                "FloatShadow",
                "FloatShadowThrough",
                -- WhichKey Popups & Text
                "WhichKey",
                "WhichKeyFloat",
                "WhichKeyNormal",
                "WhichKeyBorder",
                "WhichKeyTitle",
                "WhichKeyGroup",
                "WhichKeyDesc",
                "WhichKeySeparator",
                "WhichKeyValue",
                -- Telescope Windows, Borders, Prompts & Previews
                "TelescopeNormal",
                "TelescopeBorder",
                "TelescopePromptNormal",
                "TelescopePromptBorder",
                "TelescopePromptTitle",
                "TelescopePromptPrefix",
                "TelescopePromptCounter",
                "TelescopeResultsNormal",
                "TelescopeResultsBorder",
                "TelescopeResultsTitle",
                "TelescopePreviewNormal",
                "TelescopePreviewBorder",
                "TelescopePreviewTitle",
                "TelescopeTitle",
                "TelescopeSelection",
                "TelescopeSelectionCaret",
                -- Completion & Popups (blink.cmp / Pmenu)
                "Pmenu",
                "PmenuBorder",
                "PmenuSbar",
                "PmenuThumb",
                "PmenuExtra",
                "PmenuKind",
                -- Window Separators & Splits
                "WinSeparator",
                "VertSplit",
                -- Window Bars & Tabline
                "WinBar",
                "WinBarNC",
                "TabLine",
                "TabLineFill",
                "TabLineSel",
                -- Terminal & Inlay Hints
                "Terminal",
                "LspInlayHint",
                -- Treesitter Context
                "TreesitterContext",
                "TreesitterContextLineNumber",
                "TreesitterContextSeparator",
                "TreesitterContextBottom",
                -- NvimTree
                "NvimTreeNormal",
                "NvimTreeNormalNC",
                "NvimTreeWinSeparator",
                "NvimTreeEndOfBuffer",
                -- Line numbers & UI elements
                "LineNrAbove",
                "LineNrBelow",
                "Folded",
                "SignColumnSB",
            },
            exclude_groups = {
                -- Retain subtle cursorline highlights for active editing & tree navigation
                "CursorLine",
                "NvimTreeCursorLine",
            },
        })

        -- Clear dynamic highlight groups by prefix for transparent editor background
        transparent.clear_prefix("NvimTree")
        transparent.clear_prefix("Telescope")
        transparent.clear_prefix("WhichKey")
        transparent.clear_prefix("BlinkCmp")
        transparent.clear_prefix("Mason")
        transparent.clear_prefix("Lazy")
        transparent.clear_prefix("DapUI")
        transparent.clear_prefix("TreesitterContext")

        if vim.g.transparent_enabled then
            transparent.clear()
        end
    end,
}
