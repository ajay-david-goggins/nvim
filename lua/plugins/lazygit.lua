return {
  "kdheepak/lazygit.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local map = vim.keymap.set
    local opts = { noremap = true, silent = true }

    -- Open LazyGit UI
    map("n", "<leader>lg", ":LazyGit<CR>", { desc = "[L]azy[G]it UI" })

    -- Open LazyGit config
    map("n", "<leader>lc", ":LazyGitConfig<CR>", { desc = "[L]azyGit [C]onfig" })

    -- Stage current file (like :Git add %)
    map("n", "<leader>la", ":LazyGit git add %<CR>", { desc = "[L]azyGit [A]dd Current" })

    -- Stage all files (like :Git add .)
    map("n", "<leader>lA", ":LazyGit git add .<CR>", { desc = "[L]azyGit Add [A]ll" })

    -- Commit
    map("n", "<leader>lc", ":LazyGit git commit<CR>", { desc = "[L]azyGit [C]ommit" })

    -- Push
    map("n", "<leader>lp", ":LazyGit git push<CR>", { desc = "[L]azyGit [P]ush" })

    -- Pull
    map("n", "<leader>lP", ":LazyGit git pull<CR>", { desc = "[L]azyGit [P]ull" })

    -- Diff (opens LazyGit's diff view)
    map("n", "<leader>ld", ":LazyGit git diff<CR>", { desc = "[L]azyGit [D]iff" })

    -- Blame current file
    map("n", "<leader>lb", ":LazyGit git blame<CR>", { desc = "[L]azyGit [B]lame" })

    -- Log
    map("n", "<leader>ll", ":LazyGit git log<CR>", { desc = "[L]azyGit [L]og" })

    -- Stage hunk (like Gitsigns stage_hunk)
    map("n", "<leader>ls", ":LazyGit git add -p<CR>", { desc = "[L]azyGit [S]tage Hunk" })

    -- Undo stage hunk
    map("n", "<leader>lu", ":LazyGit git reset -p<CR>", { desc = "[L]azyGit [U]ndo Stage" })

    -- Reset hunk
    map("n", "<leader>lr", ":LazyGit git checkout -p<CR>", { desc = "[L]azyGit [R]eset Hunk" })

    -- Stage buffer (like Gitsigns stage_buffer)
    map("n", "<leader>lS", ":LazyGit git add %<CR>", { desc = "[L]azyGit Stage [B]uffer" })

    -- Toggle blame (like Gitsigns toggle_current_line_blame)
    map("n", "<leader>ltb", ":LazyGit git blame -- %<CR>", { desc = "[L]azyGit Toggle [B]lame" })

    -- Toggle deleted lines (like Gitsigns toggle_deleted)
    map("n", "<leader>ltd", ":LazyGit git diff --cached<CR>", { desc = "[L]azyGit Toggle [D]eleted" })
  end,
}
