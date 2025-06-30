return {
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = '+' },
          change       = { text = '~' },
          delete       = { text = '-' },
          topdelete    = { text = '‾' },
          changedelete = { text = '~' },
          untracked    = { text = '┆' },
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        current_line_blame = false,
        update_debounce = 100,
        max_file_length = 40000,
      })

      local map = vim.keymap.set

      -- GitSigns keymaps
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
  {
    "tpope/vim-fugitive",
    config = function()
      local map = vim.keymap.set

      -- Fugitive keymaps
      map("n", "<leader>gs", ":Git<CR>", { desc = "[G]it [S]tatus", silent = true })
      map("n", "<leader>gd", ":Gvdiffsplit<CR>", { desc = "[G]it [D]iff Split", silent = true })
      map("n", "<leader>gb", ":Git blame<CR>", { desc = "[G]it [B]lame", silent = true })
      map("n", "<leader>ga", ":Git add %<CR>", { desc = "[G]it [A]dd Current", silent = true })
      map("n", "<leader>gA", ":Git add .<CR>", { desc = "[G]it Add [A]ll", silent = true })
      map("n", "<leader>gc", ":Git commit<CR>", { desc = "[G]it [C]ommit", silent = true })
      map("n", "<leader>gp", ":Git push<CR>", { desc = "[G]it [P]ush", silent = true })
      map("n", "<leader>gP", ":Git pull<CR>", { desc = "[G]it [P]ull", silent = true })
      map("n", "<leader>glg", ":Git log<CR>", { desc = "[G]it [L]o[G]", silent = true })
    end,
  },
}


