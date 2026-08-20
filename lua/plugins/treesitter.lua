return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",

    dependencies = {
        "windwp/nvim-ts-autotag",
    },

    config = function()
        require("nvim-treesitter").setup()

        require("nvim-treesitter").install({
            "lua",
            "vim",
            "vimdoc",
            "javascript",
            "typescript",
            "tsx",
            "html",
            "css",
            "json",
            "python",
            "c",
            "rust",
            "markdown",
        })

        vim.api.nvim_create_autocmd("FileType", {
            callback = function()
                pcall(vim.treesitter.start)
            end,
        })
    end,
}

