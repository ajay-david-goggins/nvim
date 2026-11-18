return {
    "Mofiqul/dracula.nvim",
    lazy = false,
    priority = 1000, -- load this plugin first before default
    config = function()
        local dracula = require("dracula")
        dracula.setup({
            show_end_of_buffer = true,
            transparent_bg = false, -- handled dynamically by transparent.nvim for instant toggling
            italic_comment = false, -- bold comments are far more readable than thin italic on bright wallpapers
            colors = {
                fg = "#FFFFFF",            -- Crisp pure white base text
                selection = "#44475A",
                comment = "#00FF7F",       -- Vivid Spring/Neon Green (high contrast on transparent wallpaper)
                red = "#FF5555",           -- Bright Coral Red
                orange = "#FF9F43",        -- Vivid Amber/Orange (replaces pale peach #FFB86C)
                yellow = "#FFD700",        -- Rich Vivid Gold (replaces washed-out pastel #F1FA8C)
                green = "#50FA7B",         -- Vivid Neon Emerald Green
                purple = "#BD93F9",        -- Bright Electric Lavender
                cyan = "#00E5FF",          -- Electric High-Contrast Cyan (replaces pale pastel #8BE9FD)
                pink = "#FF79C6",          -- Vivid Neon Pink
                bright_red = "#FF6E6E",
                bright_green = "#69FF94",
                bright_yellow = "#FFFFA5",
                bright_blue = "#D6ACFF",
                bright_magenta = "#FF92DF",
                bright_cyan = "#A4FFFF",
                bright_white = "#FFFFFF",
            },
            overrides = {
                -- Base editor & Line Numbers
                Normal = { fg = "#FFFFFF", bg = "#282A36" },
                NormalNC = { fg = "#E2E8F0", bg = "#282A36" },
                LineNr = { fg = "#FFFFFF", bold = true },
                LineNrAbove = { fg = "#CBD5E1" },
                LineNrBelow = { fg = "#CBD5E1" },
                CursorLineNr = { fg = "#00FFFF", bold = true },

                -- Comments (Vivid, bold, clearly legible across bright spots)
                Comment = { fg = "#00FF7F", bold = true },
                SpecialComment = { fg = "#00FF7F", bold = true },

                -- Keywords & Control flow (Bold punchy neon pink)
                Keyword = { fg = "#FF79C6", bold = true },
                Keywords = { fg = "#FF79C6", bold = true },
                Statement = { fg = "#FF79C6", bold = true },
                Conditional = { fg = "#FF79C6", bold = true },
                Repeat = { fg = "#FF79C6", bold = true },
                Label = { fg = "#00E5FF", bold = true },
                Exception = { fg = "#FF79C6", bold = true },
                PreProc = { fg = "#BD93F9", bold = true },
                Include = { fg = "#FF79C6", bold = true },
                Define = { fg = "#FF79C6", bold = true },
                Macro = { fg = "#00E5FF", bold = true },

                -- Functions & Methods (Bold bright neon green)
                Function = { fg = "#50FA7B", bold = true },

                -- Types & Classes (Bold electric cyan)
                Type = { fg = "#00E5FF", bold = true },
                TypeDef = { fg = "#00E5FF", bold = true },
                Structure = { fg = "#00E5FF", bold = true },
                StorageClass = { fg = "#FF79C6", bold = true },

                -- Strings (Rich bright gold/amber - prevents washout against bright background image)
                String = { fg = "#FFD700", bold = true },
                Character = { fg = "#50FA7B", bold = true },

                -- Constants, Numbers, Booleans (Bold purple/violet & warm amber)
                Constant = { fg = "#BD93F9", bold = true },
                Number = { fg = "#BD93F9", bold = true },
                Float = { fg = "#BD93F9", bold = true },
                Boolean = { fg = "#FF9F43", bold = true },

                -- Identifiers, Operators, Delimiters
                Identifier = { fg = "#FFFFFF", bold = true },
                Operator = { fg = "#FF79C6", bold = true },
                Special = { fg = "#00E5FF", bold = true },
                ["@punctuation.bracket"] = { fg = "#FFFFFF", bold = true },
                ["@punctuation.delimiter"] = { fg = "#FFFFFF", bold = true },
                ["@punctuation.special"] = { fg = "#00E5FF", bold = true },
                ["@punctuation.bracket.javascript"] = { link = "String" },

                -- TreeSitter core syntax tokens
                ["@variable"] = { fg = "#FFFFFF", bold = true },
                ["@variable.builtin"] = { fg = "#BD93F9", bold = true },
                ["@variable.parameter"] = { fg = "#FF9F43", bold = true },
                ["@variable.member"] = { fg = "#FFB86C", bold = true },
                ["@property"] = { fg = "#FFB86C", bold = true },
                ["@field"] = { fg = "#FFB86C", bold = true },

                ["@function"] = { fg = "#50FA7B", bold = true },
                ["@function.builtin"] = { fg = "#00E5FF", bold = true },
                ["@function.method"] = { fg = "#50FA7B", bold = true },
                ["@function.macro"] = { fg = "#50FA7B", bold = true },
                ["@function.call"] = { fg = "#50FA7B", bold = true },

                ["@keyword"] = { fg = "#FF79C6", bold = true },
                ["@keyword.function"] = { fg = "#00E5FF", bold = true },
                ["@keyword.return"] = { fg = "#FF79C6", bold = true },
                ["@keyword.conditional"] = { fg = "#FF79C6", bold = true },
                ["@keyword.repeat"] = { fg = "#FF79C6", bold = true },
                ["@keyword.import"] = { fg = "#FF79C6", bold = true },
                ["@keyword.operator"] = { fg = "#FF79C6", bold = true },
                ["@keyword.coroutine"] = { fg = "#FF79C6", bold = true },
                ["@keyword.export"] = { fg = "#FF79C6", bold = true },

                ["@type"] = { fg = "#00E5FF", bold = true },
                ["@type.builtin"] = { fg = "#00E5FF", bold = true },
                ["@type.definition"] = { fg = "#00E5FF", bold = true },
                ["@type.qualifier"] = { fg = "#FF79C6", bold = true },

                ["@string"] = { fg = "#FFD700", bold = true },
                ["@string.regex"] = { fg = "#FF5555", bold = true },
                ["@string.escape"] = { fg = "#00E5FF", bold = true },
                ["@string.special"] = { fg = "#BD93F9", bold = true },

                ["@constant"] = { fg = "#BD93F9", bold = true },
                ["@constant.builtin"] = { fg = "#BD93F9", bold = true },
                ["@constant.macro"] = { fg = "#00E5FF", bold = true },

                ["@number"] = { fg = "#BD93F9", bold = true },
                ["@number.float"] = { fg = "#BD93F9", bold = true },
                ["@boolean"] = { fg = "#FF9F43", bold = true },

                ["@comment"] = { fg = "#00FF7F", bold = true },
                ["@comment.documentation"] = { fg = "#00FF7F", bold = true },
                ["@operator"] = { fg = "#FF79C6", bold = true },

                ["@tag"] = { fg = "#00E5FF", bold = true },
                ["@tag.attribute"] = { fg = "#50FA7B", bold = true },
                ["@tag.delimiter"] = { fg = "#00E5FF", bold = true },

                -- LSP Semantic Tokens (Neovim 0.10+)
                ["@lsp.type.class"] = { fg = "#00E5FF", bold = true },
                ["@lsp.type.struct"] = { fg = "#00E5FF", bold = true },
                ["@lsp.type.type"] = { fg = "#00E5FF", bold = true },
                ["@lsp.type.typeParameter"] = { fg = "#00E5FF", bold = true },
                ["@lsp.type.interface"] = { fg = "#00E5FF", bold = true },
                ["@lsp.type.function"] = { fg = "#50FA7B", bold = true },
                ["@lsp.type.method"] = { fg = "#50FA7B", bold = true },
                ["@lsp.type.macro"] = { fg = "#00E5FF", bold = true },
                ["@lsp.type.parameter"] = { fg = "#FF9F43", bold = true },
                ["@lsp.type.variable"] = { fg = "#FFFFFF", bold = true },
                ["@lsp.type.keyword"] = { fg = "#FF79C6", bold = true },
                ["@lsp.type.property"] = { fg = "#FFB86C", bold = true },
                ["@lsp.type.namespace"] = { fg = "#00E5FF", bold = true },
                ["@lsp.type.decorator"] = { fg = "#BD93F9", bold = true },
                ["@lsp.type.enum"] = { fg = "#00E5FF", bold = true },
                ["@lsp.type.enumMember"] = { fg = "#BD93F9", bold = true },

                -- NvimTree under opened folder / files
                NvimTreeFolderName = { fg = "#00E5FF", bold = true },
                NvimTreeOpenedFolderName = { fg = "#50FA7B", bold = true },
                NvimTreeEmptyFolderName = { fg = "#8892B0", bold = true },
                NvimTreeFolderIcon = { fg = "#BD93F9", bold = true },
                NvimTreeOpenedFolderIcon = { fg = "#50FA7B", bold = true },
                NvimTreeClosedFolderIcon = { fg = "#BD93F9", bold = true },
                NvimTreeFile = { fg = "#FFFFFF", bold = true },
                NvimTreeOpenedHL = { fg = "#FFD700", bold = true },
                NvimTreeOpenedFile = { fg = "#FFD700", bold = true },
                NvimTreeExecFile = { fg = "#50FA7B", bold = true },
                NvimTreeSpecialFile = { fg = "#FF79C6", bold = true },
                NvimTreeImageFile = { fg = "#FF79C6", bold = true },
                NvimTreeRootFolder = { fg = "#FFD700", bold = true },
                NvimTreeGitDirty = { fg = "#FF9F43", bold = true },
                NvimTreeGitNew = { fg = "#50FA7B", bold = true },
                NvimTreeIndentMarker = { fg = "#6272A4" },
                NvimTreeCursorLine = { bg = "#2C2C2C" },

                -- Diagnostics (High-contrast bold badges)
                DiagnosticError = { fg = "#FF5555", bold = true },
                DiagnosticWarn = { fg = "#FF9F43", bold = true },
                DiagnosticInfo = { fg = "#00E5FF", bold = true },
                DiagnosticHint = { fg = "#00FF7F", bold = true },

                -- Search & Selection Visibility
                Search = { fg = "#000000", bg = "#FFD700", bold = true },
                IncSearch = { fg = "#000000", bg = "#00FFFF", bold = true },
                MatchParen = { fg = "#00FFFF", bold = true, underline = true },
                CursorLine = { bg = "#44475A" },

                -- Floating Popups (Telescope, WhichKey, Float Windows)
                -- Configured with Dracula solid dark backgrounds for Solid mode (<leader>tr toggle),
                -- dynamically cleared to transparent NONE by transparent.nvim when transparent mode is active.
                NormalFloat = { fg = "#FFFFFF", bg = "#21222C" },
                NormalFloatNC = { fg = "#E2E8F0", bg = "#21222C" },
                FloatBorder = { fg = "#BD93F9", bg = "#21222C" },
                FloatTitle = { fg = "#50FA7B", bg = "#21222C", bold = true },
                FloatShadow = { bg = "NONE" },
                FloatShadowThrough = { bg = "NONE" },
                WhichKeyNormal = { fg = "#FFFFFF", bg = "#21222C" },
                WhichKeyBorder = { fg = "#BD93F9", bg = "#21222C" },
                WhichKeyTitle = { fg = "#50FA7B", bg = "#21222C", bold = true },
                WhichKeyFloat = { fg = "#FFFFFF", bg = "#21222C" },
                WhichKeyGroup = { fg = "#00E5FF", bold = true },
                WhichKeyDesc = { fg = "#FFFFFF", bold = true },
                WhichKey = { fg = "#50FA7B", bold = true },
                WhichKeySeparator = { fg = "#6272A4" },
                TelescopeNormal = { fg = "#FFFFFF", bg = "#21222C" },
                TelescopeBorder = { fg = "#BD93F9", bg = "#21222C" },
                TelescopePromptNormal = { fg = "#FFFFFF", bg = "#1E1F29" },
                TelescopePromptBorder = { fg = "#00E5FF", bg = "#1E1F29" },
                TelescopePromptTitle = { fg = "#00E5FF", bg = "#1E1F29", bold = true },
                TelescopePromptPrefix = { fg = "#00E5FF", bg = "#1E1F29", bold = true },
                TelescopePromptCounter = { fg = "#BD93F9", bg = "#1E1F29", bold = true },
                TelescopeResultsNormal = { fg = "#FFFFFF", bg = "#21222C" },
                TelescopeResultsBorder = { fg = "#BD93F9", bg = "#21222C" },
                TelescopeResultsTitle = { fg = "#50FA7B", bg = "#21222C", bold = true },
                TelescopePreviewNormal = { fg = "#FFFFFF", bg = "#191A21" },
                TelescopePreviewBorder = { fg = "#6272A4", bg = "#191A21" },
                TelescopePreviewTitle = { fg = "#FFD700", bg = "#191A21", bold = true },
                TelescopeTitle = { fg = "#BD93F9", bg = "#21222C", bold = true },
                TelescopeSelection = { fg = "#00FFFF", bg = "#44475A", bold = true },
                TelescopeSelectionCaret = { fg = "#50FA7B", bg = "#21222C", bold = true },
                TelescopeMatching = { fg = "#FF79C6", bold = true },
                Pmenu = { fg = "#FFFFFF", bg = "#21222C" },
                PmenuBorder = { fg = "#BD93F9", bg = "#21222C" },
                PmenuSel = { fg = "#00FFFF", bg = "#44475A", bold = true },
                TabLine = { fg = "#6272A4", bg = "#21222C" },
                TabLineFill = { bg = "#282A36" },
                TabLineSel = { fg = "#FFFFFF", bg = "#282A36", bold = true },
                WinBar = { fg = "#FFFFFF", bg = "#282A36" },
                WinBarNC = { fg = "#6272A4", bg = "#282A36" },
            },
        })
        vim.cmd.colorscheme("dracula")
    end,
}

