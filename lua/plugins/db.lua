-- =============================================================================
-- db.lua  ·  Neovim 0.13+ · vim-dadbod + dadbod-ui + dadbod-completion
-- =============================================================================
-- WHY <leader>D (uppercase) and not <leader>d:
-- <leader>d is already fully owned by Diagnostics (do/dp/dn/dq) and DAP-ish
-- jdtls keys (dt/dT) in lsp-configs.lua. Lua/Vim keymaps are case-sensitive,
-- so <leader>D is a completely separate, collision-free namespace — same
-- trick already used in this config for <leader>hR / <leader>hS (uppercase
-- = "buffer-wide" variant of the lowercase hunk keys).
-- =============================================================================

return {
    {
        "tpope/vim-dadbod",
        lazy = true,
    },

    {
        "kristijanhusak/vim-dadbod-ui",
        dependencies = { "tpope/vim-dadbod" },
        -- Lazy registers these keys on startup without executing heavy code.
        -- Pressing any <leader>D key instantly lazy-loads vim-dadbod-ui.
        keys = {
            { "<leader>du", "<cmd>DBUIToggle<CR>",         desc = "[D]atabase [U]I Toggle" },
            { "<leader>dc", "<cmd>DBUIAddConnection<CR>",   desc = "[D]atabase [C]onnection Add" },
            { "<leader>df", "<cmd>DBUIFindBuffer<CR>",      desc = "[D]atabase [F]ind Buffer" },
            { "<leader>dr", "<cmd>DBUIRenameBuffer<CR>",    desc = "[D]atabase [R]ename Buffer" },
            { "<leader>dq", "<cmd>DBUILastQueryInfo<CR>",  desc = "[D]atabase last [Q]uery Info" },
        },
        cmd = {
            "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer",
        },
        init = function()
            -- dadbod-ui reads these BEFORE it loads, so set in init(), not config()
            vim.g.db_ui_use_nerd_fonts     = 1
            vim.g.db_ui_show_help          = 0
            vim.g.db_ui_win_position       = "left"
            vim.g.db_ui_winwidth           = 35
            vim.g.db_ui_save_location      = vim.fn.stdpath("data") .. "/db_ui_queries"
            -- Don't auto-execute on save; keep it explicit (see buffer keymap below)
            vim.g.db_ui_execute_on_save    = 0
        end,
        config = function()
            local map = vim.keymap.set

            -- Buffer-local keymaps inside actual DB query buffers
            -- (sql / mysql / plsql / dbout / dbui), mirroring the jdtls ft-pattern
            -- already used in lsp-configs.lua for Java.
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "sql", "mysql", "plsql", "dbout", "dbui" },
                group   = vim.api.nvim_create_augroup("UserDadbodBuffer", { clear = true }),
                callback = function(args)
                    local buf = args.buf
                    local bo  = function(desc) return { buffer = buf, silent = true, desc = desc } end

                    -- Execute query: whole buffer (normal) or selection (visual)
                    -- Uses direct :DB command to prevent <Plug> resolution failures
                    map("n", "<leader>De", "<cmd>%DB<CR>", bo("[D]atabase [E]xecute query"))
                    map("v", "<leader>De", ":DB<CR>",     bo("[D]atabase [E]xecute selection"))

                    -- Save current query into the saved-queries tree
                    map("n", "<leader>Ds", "<Plug>(DBUI_SaveQuery)", bo("[D]atabase [S]ave query"))

                    -- Edit bind parameters
                    map("n", "<leader>Dd", "<Plug>(DBUI_EditBindParameters)", bo("[D]atabase e[D]it bind params"))
                end,
            })
        end,
    },

    {
        "kristijanhusak/vim-dadbod-completion",
        ft = { "sql", "mysql", "plsql" },
        dependencies = { "tpope/vim-dadbod", "hrsh7th/nvim-cmp" },
        config = function()
            -- Wire dadbod's own completion source into nvim-cmp ONLY for sql
            -- filetypes, so it doesn't fight with cmp_nvim_lsp elsewhere.
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "sql", "mysql", "plsql" },
                group   = vim.api.nvim_create_augroup("UserDadbodCmp", { clear = true }),
                callback = function()
                    require("cmp").setup.buffer({
                        sources = {
                            { name = "vim-dadbod-completion" },
                            { name = "buffer" },
                        },
                    })
                end,
            })
        end,
    },
}

-- =============================================================================
-- KEYBIND CHEATSHEET (db.lua)
-- =============================================================================
-- <leader>Du   [D]atabase [U]I toggle          (global)
-- <leader>Dc   [D]atabase [C]onnection add     (global)
-- <leader>Df   [D]atabase [F]ind buffer        (global)
-- <leader>Dr   [D]atabase [R]ename buffer      (global)
-- <leader>Dq   [D]atabase last [Q]uery info    (global)
-- <leader>De   [D]atabase [E]xecute query      (sql/mysql/plsql buffers only, n+v)
-- <leader>Ds   [D]atabase [S]ave query         (sql/mysql/plsql buffers only)
-- <leader>Dd   [D]atabase e[D]it bind params   (sql/mysql/plsql buffers only)
-- =============================================================================
