return {
    "Mofiqul/dracula.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd.colorscheme "dracula"

        -- Change comment color to bright green
        vim.api.nvim_set_hl(0, "Comment", { fg = "#00FF00", bg = "NONE", italic = true })

        -- Optional: command-line neon green
        vim.api.nvim_set_hl(0, "CommandLine", { fg = "#ADFF2F", bg = "NONE" })

        -- 🔹 Folded text: yellow-green, transparent background
        vim.api.nvim_set_hl(0, "Folded", { fg = "#ccff66", bg = "NONE", bold = true })

        -- (Optional) Fold column (the + / - signs at left)
        vim.api.nvim_set_hl(0, "FoldColumn", { fg = "#ccff66", bg = "NONE" })
    end
}

