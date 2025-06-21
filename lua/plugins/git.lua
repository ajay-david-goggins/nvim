return {
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({})

            local map = vim.keymap.set
            local opts = { noremap = true, silent = true }

            -- Preview current hunk
            map("n", "<leader>gh", ":Gitsigns preview_hunk<CR>", { desc = "[G]it Preview [H]unk" })

            -- Next/Previous Hunk
            map("n", "<leader>gj", ":Gitsigns next_hunk<CR>", { desc = "[G]it Next Hunk" })
            map("n", "<leader>gk", ":Gitsigns prev_hunk<CR>", { desc = "[G]it Prev Hunk" })

            -- Stage / Undo Stage / Reset Hunk
            map("n", "<leader>gs", ":Gitsigns stage_hunk<CR>", { desc = "[G]it [S]tage Hunk" })
            map("n", "<leader>gu", ":Gitsigns undo_stage_hunk<CR>", { desc = "[G]it [U]ndo Stage" })
            map("n", "<leader>gr", ":Gitsigns reset_hunk<CR>", { desc = "[G]it [R]eset Hunk" })

            -- Stage whole buffer
            map("n", "<leader>gS", ":Gitsigns stage_buffer<CR>", { desc = "[G]it Stage [B]uffer" })

            -- Blame line
            map("n", "<leader>gl", ":Gitsigns blame_line<CR>", { desc = "[G]it [L]ine Blame" })

            -- Toggle blame & deleted lines
            map("n", "<leader>gtb", ":Gitsigns toggle_current_line_blame<CR>", { desc = "Toggle Blame" })
            map("n", "<leader>gtd", ":Gitsigns toggle_deleted<CR>", { desc = "Toggle Deleted" })
        end,
    },
    {
        "tpope/vim-fugitive",
        config = function()
            local map = vim.keymap.set
            local opts = { noremap = true, silent = true }

            -- Git status (like `git status`)
            map("n", "<leader>gs", ":Git<CR>", { desc = "[G]it [S]tatus" })

            -- Git diff
            map("n", "<leader>gd", ":Gvdiffsplit<CR>", { desc = "[G]it [D]iff Split" })

            -- Blame current file
            map("n", "<leader>gb", ":Git blame<CR>", { desc = "[G]it [B]lame" })

            -- Add current file
            map("n", "<leader>ga", ":Git add %<CR>", { desc = "[G]it [A]dd Current" })

            -- Add all files
            map("n", "<leader>gA", ":Git add .<CR>", { desc = "[G]it Add [A]ll" })

            -- Commit
            map("n", "<leader>gc", ":Git commit<CR>", { desc = "[G]it [C]ommit" })

            -- Push
            map("n", "<leader>gp", ":Git push<CR>", { desc = "[G]it [P]ush" })

            -- Pull
            map("n", "<leader>gP", ":Git pull<CR>", { desc = "[G]it [P]ull" })

            -- Git log
            map("n", "<leader>glg", ":Git log<CR>", { desc = "[G]it [L]o[G]" })
        end,
    },
}

