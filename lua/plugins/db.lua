-- =============================================================================
-- db.lua  ·  Neovim 0.13+ · vim-dadbod + dadbod-ui + dadbod-completion
-- =============================================================================
-- ROOT CAUSE OF THE ORIGINAL BUG (for future-me):
-- `cmd = {...}` was the ONLY lazy-load trigger, and every keymap was defined
-- inside config(). Lazy.nvim will not run config() until one of the `cmd`
-- names is invoked — but the only way to invoke :DBUIToggle was the keymap,
-- which didn't exist yet because config() hadn't run. Chicken-and-egg:
--
--   [Neovim starts] → plugin NOT loaded → <leader>?? not registered
--   → keypress falls through to native Neovim → "de" = delete-to-end-of-word
--   (this is exactly what was eating the character after the cursor)
--
-- THE PERMANENT FIX: give lazy.nvim a `keys = {...}` spec. Lazy pre-registers
-- those exact key sequences as real (but empty) mappings on startup, BEFORE
-- the plugin loads. The first time you press one, lazy intercepts it, loads
-- the plugin (running config(), which then defines the real mapping), and
-- replays the keypress. `ft` is added too so opening/entering a query buffer
-- loads the plugin even if you never touched a global keymap first.
-- =============================================================================
-- NAMESPACE: <leader>db  (not uppercase <leader>D)
-- <leader>d already has complete 2-key leaves: do/dp/dn/dq (diagnostics) and
-- dt/dT (jdtls test). Those are DIFFERENT branches in the keymap trie from
-- <leader>db*, so "db" as a 3-key prefix never collides with them — no need
-- to switch case at all.
-- =============================================================================

return {
    {
        "tpope/vim-dadbod",
        lazy = true,
    },

    {
        "kristijanhusak/vim-dadbod-ui",
        dependencies = { "tpope/vim-dadbod" },
        cmd = {
            "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer",
        },
        -- 🌟 THE FIX: lazy-load on either a keypress or entering a DB filetype
        ft = { "sql", "mysql", "plsql" },
        keys = {
            { "<leader>du", "<cmd>DBUIToggle<CR>",        desc = "[D]ata[B]ase [U]I Toggle" },
            { "<leader>dc", "<cmd>DBUIAddConnection<CR>", desc = "[D]ata[B]ase [C]onnection Add" },
            { "<leader>df", "<cmd>DBUIFindBuffer<CR>",    desc = "[D]ata[B]ase [F]ind Buffer" },
            { "<leader>dr", "<cmd>DBUIRenameBuffer<CR>",  desc = "[D]ata[B]ase [R]ename Buffer" },
            { "<leader>dq", "<cmd>DBUILastQueryInfo<CR>", desc = "[D]ata[B]ase last [Q]uery Info" },
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
            local db_filetypes = { "sql", "mysql", "plsql" }

            -- Buffer-local keymaps only inside actual DB query buffers
            -- (sql / mysql / plsql / dbout), mirroring the jdtls ft-pattern
            -- already used in lsp-configs.lua for Java.
            local function apply_dbui_buffer_keymaps(buf)
                local bo = function(desc) return { buffer = buf, silent = true, desc = desc } end

                -- Execute query: whole buffer (normal) or selection (visual)
                vim.keymap.set("n", "<leader>de", "<Plug>(DBUI_ExecuteQuery)", bo("[D]ata[B]ase [E]xecute query"))
                vim.keymap.set("v", "<leader>de", "<Plug>(DBUI_ExecuteQuery)", bo("[D]ata[B]ase [E]xecute selection"))

                -- Save current query into the saved-queries tree
                vim.keymap.set("n", "<leader>ds", "<Plug>(DBUI_SaveQuery)", bo("[D]ata[B]ase [S]ave query"))

                -- Edit bind parameters
                vim.keymap.set("n", "<leader>dd", "<Plug>(DBUI_EditBindParameters)", bo("[D]ata[B]ase e[D]it bind params"))
            end

            -- Covers every FUTURE sql/mysql/plsql buffer.
            vim.api.nvim_create_autocmd("FileType", {
                pattern  = db_filetypes,
                group    = vim.api.nvim_create_augroup("UserDadbodBuffer", { clear = true }),
                callback = function(args)
                    apply_dbui_buffer_keymaps(args.buf)
                end,
            })

            -- 🌟 RACE-CONDITION FIX: if the `ft` trigger above is what caused
            -- THIS config() to run in the first place, the FileType event for
            -- the CURRENT buffer already fired before the autocmd right above
            -- existed — so it would never get the keymap otherwise. Catch it
            -- explicitly, once, right here.
            local cur_buf = vim.api.nvim_get_current_buf()
            if vim.tbl_contains(db_filetypes, vim.bo[cur_buf].filetype) then
                apply_dbui_buffer_keymaps(cur_buf)
            end

            -- Sanity check you can run any time:
            -- :set filetype?        → confirms filetype is "sql"/"mysql"/"plsql"
            -- :map <leader>dbe      → confirms the buffer-local map exists
            -- :verbose map <leader>dbe → shows WHERE it was last set (or that it's undefined)
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
-- <leader>dbu   [D]ata[B]ase [U]I toggle          (global, always available)
-- <leader>dbc   [D]ata[B]ase [C]onnection add     (global, always available)
-- <leader>dbf   [D]ata[B]ase [F]ind buffer        (global, always available)
-- <leader>dbr   [D]ata[B]ase [R]ename buffer      (global, always available)
-- <leader>dbq   [D]ata[B]ase last [Q]uery info    (global, always available)
-- <leader>dbe   [D]ata[B]ase [E]xecute query      (sql/mysql/plsql buffers only, n+v)
-- <leader>dbs   [D]ata[B]ase [S]ave query         (sql/mysql/plsql buffers only)
-- <leader>dbd   [D]ata[B]ase e[D]it bind params   (sql/mysql/plsql buffers only)
-- =============================================================================
