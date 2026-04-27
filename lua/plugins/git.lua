-- =============================================================================
-- plugins/git.lua  ·  Gitsigns + Fugitive  ·  (your existing config, trimmed)
-- =============================================================================

return {

    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            signs = {
                add          = { text = "+" },
                change       = { text = "~" },
                delete       = { text = "-" },
                topdelete    = { text = "^" },
                changedelete = { text = "/" },
            },
            current_line_blame = true,
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = "eol",
                delay = 500,            -- longer delay = less work on mobile
            },
            current_line_blame_formatter = "<abbrev_sha> · <author> · <author_time:%d %b %Y>",
            on_attach = function(bufnr)
                local gs  = package.loaded.gitsigns
                local map = function(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
                end
                map("n", "]h",         gs.next_hunk,                                  "Next hunk")
                map("n", "[h",         gs.prev_hunk,                                  "Prev hunk")
                map("n", "<leader>hp", gs.preview_hunk,                               "Hunk preview")
                map("n", "<leader>hs", gs.stage_hunk,                                 "Stage hunk")
                map("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage hunk (visual)")
                map("n", "<leader>hu", gs.undo_stage_hunk,                            "Undo stage")
                map("n", "<leader>hr", gs.reset_hunk,                                 "Reset hunk")
                map("n", "<leader>gb", function() gs.blame_line({ full = true }) end,  "Blame line")
                map("n", "<leader>gd", gs.diffthis,                                   "Diff this")
            end,
        },
    },

    {
        "tpope/vim-fugitive",
        cmd  = { "Git", "G" },
        keys = { "<leader>g" },
        config = function()
            local map = vim.keymap.set
            local o   = function(desc) return { desc = desc, silent = true } end
            map("n", "<leader>gS",  ":Git<CR>",             o("Git status"))
            map("n", "<leader>gaa", ":Git add .<CR>",        o("Git add all"))
            map("n", "<leader>gcm", ":Git commit<CR>",       o("Git commit"))
            map("n", "<leader>gp",  ":Git push<CR>",         o("Git push"))
            map("n", "<leader>gP",  ":Git pull<CR>",         o("Git pull"))
            map("n", "<leader>glg", ":Git log --oneline<CR>",o("Git log"))

            -- Auto add + commit + push
            map("n", "<leader>gacp", function()
                local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n","")
                vim.cmd("Git add .")
                vim.cmd("Git commit -m '" .. branch .. " - published'")
                vim.cmd("Git push -u origin HEAD")
            end, o("Git add-commit-push"))
        end,
    },
    -- Lazygit
    {
        "kdheepak/lazygit.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        cmd  = "LazyGit",
        keys = {
            { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
        },
    },
}
