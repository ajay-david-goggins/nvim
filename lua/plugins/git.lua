return {
    -- ✅ Git Signs
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                signs = {
                    add          = { text = "+" },
                    change       = { text = "~" },
                    delete       = { text = "-" },
                    topdelete    = { text = "‾" },
                    changedelete = { text = "~" },
                    untracked    = { text = "┆" },
                },
                signcolumn = true,
                numhl = false,
                linehl = false,
                current_line_blame = true,
                current_line_blame_opts = {
                    delay = 1000,
                    ignore_whitespace = true,
                },
                current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
                update_debounce = 100,
                max_file_length = 40000,
            })

            local map = vim.keymap.set
            map("n", "<leader>gh", ":Gitsigns preview_hunk<CR>", { desc = "[G]it Preview [H]unk", silent = true })
            map("n", "<leader>gj", ":Gitsigns next_hunk<CR>", { desc = "[G]it Next Hunk", silent = true })
            map("n", "<leader>gk", ":Gitsigns prev_hunk<CR>", { desc = "[G]it Prev Hunk", silent = true })
            map("n", "<leader>gs", ":Gitsigns stage_hunk<CR>", { desc = "[G]it [S]tage Hunk", silent = true })
            map("n", "<leader>gu", ":Gitsigns undo_stage_hunk<CR>", { desc = "[G]it [U]ndo Stage", silent = true })
            map("n", "<leader>gr", ":Gitsigns reset_hunk<CR>", { desc = "[G]it [R]eset Hunk", silent = true })
            map("n", "<leader>gS", ":Gitsigns stage_buffer<CR>", { desc = "[G]it Stage [B]uffer", silent = true })
            map("n", "<leader>gl", ":Gitsigns blame_line<CR>", { desc = "[G]it [L]ine Blame", silent = true })

            map("n", "<leader>gtb", ":Gitsigns toggle_current_line_blame<CR>", { desc = "Toggle Blame", silent = true })
            map("n", "<leader>gtd", ":Gitsigns toggle_deleted<CR>", { desc = "Toggle Deleted", silent = true })
        end,
    },

    -- ✅ Fugitive for full Git CLI
    {
        "tpope/vim-fugitive",
        config = function()
            local map = vim.keymap.set
            map("n", "<leader>gs", ":Git<CR>", { desc = "[G]it [S]tatus", silent = true })
            map("n", "<leader>gd", ":Gvdiffsplit<CR>", { desc = "[G]it [D]iff Split", silent = true })
            map("n", "<leader>gb", ":Git blame<CR>", { desc = "[G]it [B]lame", silent = true })
            map("n", "<leader>ga", ":Git add %<CR>", { desc = "[G]it Add Current File", silent = true })
            map("n", "<leader>gA", ":Git add .<CR>", { desc = "[G]it Add All", silent = true })
            map("n", "<leader>gc", ":Git commit<CR>", { desc = "[G]it [C]ommit", silent = true })
            map("n", "<leader>gp", ":Git push<CR>", { desc = "[G]it [P]ush", silent = true })
            map("n", "<leader>gP", ":Git pull<CR>", { desc = "[G]it [P]ull", silent = true })
            map("n", "<leader>glg", ":Git log<CR>", { desc = "[G]it [L]o[G]", silent = true })
            map("n", "<leader>gcb", ":Git checkout -b ", { desc = "[G]it [C]reate [B]ranch", silent = true })
            map("n", "<leader>gco", ":Git checkout ", { desc = "[G]it [C]heckout Branch", silent = true })
            map("n", "<leader>gmg", ":Git merge ", { desc = "[G]it [M]er[G]e", silent = true })
        end,
    },

    -- ✅ Diffview
    {
        "sindrets/diffview.nvim",
        config = function()
            require("diffview").setup({})
            local map = vim.keymap.set
            map("n", "<leader>gdo", ":DiffviewOpen<CR>", { desc = "[G]it [D]iff [O]pen", silent = true })
            map("n", "<leader>gdc", ":DiffviewClose<CR>", { desc = "[G]it [D]iff [C]lose", silent = true })
            map("n", "<leader>gdh", ":DiffviewFileHistory %<CR>", { desc = "[G]it [D]iff [H]istory File", silent = true })
            map("n", "<leader>gda", ":DiffviewFileHistory<CR>", { desc = "[G]it [D]iff [A]ll History", silent = true })
        end,
    },

    -- ✅ Git Worktree
    {
        "ThePrimeagen/git-worktree.nvim",
        dependencies = { "nvim-telescope/telescope.nvim" },
        config = function()
            require("git-worktree").setup({})
            require("telescope").load_extension("git_worktree")
            local map = vim.keymap.set
            map("n", "<leader>gwt", ":Telescope git_worktree git_worktrees<CR>", { desc = "[G]it [W]ork[T]ree List" })
            map("n", "<leader>gwn", ":Telescope git_worktree create_git_worktree<CR>", { desc = "[G]it [W]orktree [N]ew" })
        end,
    },

    -- ✅ Neogit
    {
        "NeogitOrg/neogit",
        dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
        config = function()
            require("neogit").setup({})
            vim.keymap.set("n", "<leader>gn", ":Neogit<CR>", { desc = "[G]it [N]eogit", silent = true })
        end,
    },
}

