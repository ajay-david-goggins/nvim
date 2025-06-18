return {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
        "windwp/nvim-ts-autotag",
    },
    build = ":TSUpdate",
    config = function()
        -- ✅ Fix: define ts_config first
        local ts_config = require("nvim-treesitter.configs")

        -- ✅ Then configure setup
        ts_config.setup({
            ensure_installed = {
                "vim", "vimdoc", "lua", "java", "javascript", "typescript",
                "html", "css", "json", "tsx", "markdown", "markdown_inline",
                "gitignore", "php", "phpdoc"
            },
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
            indent = {
                enable = true
            },
            autotag = {
                enable = true,
                filetypes = { "html", "xml", "php" }
            }
        })
    end,
}

