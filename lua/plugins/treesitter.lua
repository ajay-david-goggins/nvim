-- return {
--     "nvim-treesitter/nvim-treesitter",
--     version = false,
--     build = ":TSUpdate",
--     -- The new version strictly says: "This plugin does not support lazy-loading."
--     lazy = false,
--
--     dependencies = {
--         "windwp/nvim-ts-autotag",
--     },
--
--     config = function()
--         -- 1. Use the new setup call directly on the main module
--         require('nvim-treesitter').setup({
--             -- Directory you saw in the docs
--             install_dir = vim.fn.stdpath('data') .. '/site'
--         })
--
--         -- 2. Install your languages (This is the new way to do ensure_installed)
--         require('nvim-treesitter').install({
--             "vim", "vimdoc", "lua", "java", "javascript", "typescript",
--             "html", "css", "json", "tsx", "markdown", "c", "rust", "python"
--         })
--
--         -- 3. ENABLE HIGHLIGHTING (The Native 0.13 way)
--         -- The docs say: use vim.treesitter.start() via autocmd
--         vim.api.nvim_create_autocmd('FileType', {
--             callback = function()
--                 local ok, _ = pcall(vim.treesitter.start)
--                 if not ok then return end
--             end,
--         })
--
--         -- 4. ENABLE FOLDING & INDENT (As per your grep)
--         vim.api.nvim_create_autocmd('FileType', {
--             callback = function()
--                 -- vim.wo.foldmethod = 'expr'
--                 vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
--                 -- Experimental indent from the docs
--                 vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
--             end,
--         })
--     end,
-- }
return {
    "nvim-treesitter/nvim-treesitter",

    build = ":TSUpdate",

    dependencies = {
        "windwp/nvim-ts-autotag",
    },

    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = {
                "vim",
                "vimdoc",
                "lua",
                "java",
                "javascript",
                "typescript",
                "html",
                "css",
                "json",
                "tsx",
                "markdown",
                "c",
                "rust",
                "python",
            },

            highlight = {
                enable = true,
            },

            indent = {
                enable = true,
            },

            autotag = {
                enable = true,
            },
        })
    end,
}
