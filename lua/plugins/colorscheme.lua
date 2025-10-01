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
    end
}

