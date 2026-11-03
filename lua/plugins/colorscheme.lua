return {
    "Mofiqul/dracula.nvim",
    lazy = false,
    priority = 1000, -- load this plugin first before default
    config = function()
        local dracula = require("dracula")
        dracula.setup({
            show_end_of_buffer = true,
            transparent_bg = false, -- handled dynamically by transparent.nvim for instant toggling
            italic_comment = true,
            overrides = {
                LineNr = { fg = "#ffffff" },
                LineNrAbove = { fg = "#ffffff" },
                LineNrBelow = { fg = "#ffffff" },
                CursorLineNr = { fg = "#00BFFF", bold = true },
                Comment = { fg = "#3cb371", bold = true },
                ["@punctuation.bracket.javascript"] = { link = "String" },
            },
        })
        vim.cmd.colorscheme("dracula")
    end,
}

