return {
  -- 🔍 Git signs, hunk preview & line blame
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = "+" },
          change       = { text = "~" },
          delete       = { text = "_" },
          topdelete    = { text = "‾" },
          changedelete = { text = "~" },
          untracked    = { text = "┆" },
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        current_line_blame = true,
        update_debounce = 100,
        max_file_length = 40000,
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
          end

          -- 🔁 Hunk navigation
          map("n", "<leader>gn", gs.next_hunk, "[G]it [N]ext Hunk")
          map("n", "<leader>gp", gs.prev_hunk, "[G]it [P]revious Hunk")
          map("n", "<leader>gh", gs.preview_hunk, "[G]it Preview [H]unk")
          map("v", "<leader>gs", ":Gitsigns stage_hunk<CR>", "[G]it [S]tage Hunk")

          -- 🔝 First and last hunk
          map("n", "<leader>g1", function()
            vim.cmd("1")
            gs.next_hunk()
          end, "Go to First Hunk")
          map("n", "<leader>g9", function()
            vim.cmd("normal G")
            gs.prev_hunk()
          end, "Go to Last Hunk")

          -- ✅ Stage / Reset / Undo
          map("n", "<leader>gs", gs.stage_hunk, "[G]it [S]tage Hunk")
          map("n", "<leader>gus", gs.undo_stage_hunk, "[G]it [U]ndo [S]tage")
          map("n", "<leader>grh", gs.reset_hunk, "[G]it [R]eset [H]unk")
          map("n", "<leader>gsb", gs.stage_buffer, "[G]it [S]tage [B]uffer")

          -- 📌 Blame and toggle
          map("n", "<leader>glb", gs.blame_line, "[G]it [L]ine [B]lame")
          map("n", "<leader>gtb", gs.toggle_current_line_blame, "[G]it [T]oggle [B]lame")
          map("n", "<leader>gtd", gs.toggle_deleted, "[G]it [T]oggle [D]eleted")
        end,
      })
    end,
  },

  -- 🧠 Core Git commands (via Fugitive)
  {
    "tpope/vim-fugitive",
    config = function()
      local map = vim.keymap.set

      -- 📄 File/Project Git status
      map("n", "<leader>gS", ":Git<CR>", { desc = "[G]it [S]tatus", silent = true })
      map("n", "<leader>gds", ":Gvdiffsplit<CR>", { desc = "[G]it [D]iff [S]plit", silent = true })
      map("n", "<leader>gb", ":Git blame<CR>", { desc = "[G]it [B]lame", silent = true })

      -- ✅ Git Staging/Committing
      map("n", "<leader>gac", ":Git add %<CR>", { desc = "[G]it [A]dd [C]urrent", silent = true })
      map("n", "<leader>gA", ":Git add .<CR>", { desc = "[G]it Add [A]ll", silent = true })
      map("n", "<leader>gc", ":Git commit<CR>", { desc = "[G]it [C]ommit", silent = true })

      -- 🔃 Push/Pull/Log
      map("n", "<leader>gp", ":Git push<CR>", { desc = "[G]it [p]ush", silent = true })
      map("n", "<leader>gP", ":Git pull<CR>", { desc = "[G]it [P]ull", silent = true })
      map("n", "<leader>glg", ":Git log<CR>", { desc = "[G]it [L]o[G]", silent = true })

      -- 🌱 Branch operations
      map("n", "<leader>gcb", ":Git checkout -b ", { desc = "[G]it [C]reate [B]ranch" }) -- then type new branch name
      map("n", "<leader>gco", ":Git checkout ", { desc = "[G]it [C]heckout Branch" })     -- then type branch name
      -- map("n", "<leader>gsb", ":Git switch " { desc = "[G]it [S]witch [B]ranch"})
      map("n", "<leader>gmb", ":Git merge ", { desc = "[G]it [M]erGe [B]ranch" })          -- then type branch name
    end,
  },

  -- 🧩 VSCode-style Git UI with commit graph (Neogit + Diffview)
  {
    "TimUntersberger/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
    },
    config = function()
      require("neogit").setup({
        integrations = {
          diffview = true,
        },
      })

      local map = vim.keymap.set
      map("n", "<leader>gg", ":Neogit<CR>", { desc = "[G]it [G]UI", silent = true })
      map("n", "<leader>ggl", ":DiffviewLog<CR>", { desc = "[G]it Commit [G]raph [L]ogs", silent = true })
      map("n", "<leader>ggd", ":DiffviewOpen<CR>", { desc = "[G]it [G]ui [D]iff View", silent = true })
      map("n", "<leader>ggc", ":DiffviewClose<CR>", { desc = "[G]it [D]iff [C]lose", silent = true })
    end,
  },
}

