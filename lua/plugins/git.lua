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
        current_line_blame_opts = {
          delay = 100,
          ignore_whitespace = true,
        },
        current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
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


          -- 🔝 First and last hunk
          map("n", "<leader>g1", function()
            vim.cmd("1")
            gs.next_hunk()
          end, "[G]o to First Hunk")
          map("n", "<leader>g9", function()
            vim.cmd("normal G")
            gs.prev_hunk()
          end, "[G]o to Last Hunk")

          -- ✅ Stage / Reset / Undo
          map("n", "<leader>gs", gs.stage_hunk, "[G]it [S]tage Hunk")
          map("v", "<leader>gs", ":Gitsigns stage_hunk<CR>", "[G]it [S]tage Hunk (Visual)")
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

      -- 📄 Status & Diff
      map("n", "<leader>gS", ":Git<CR>", { desc = "[G]it [S]tatus", silent = true })
      map("n", "<leader>gds", ":Gvdiffsplit<CR>", { desc = "[G]it [D]iff [S]plit", silent = true })
      map("n", "<leader>gb", ":Git blame<CR>", { desc = "[G]it [B]lame", silent = true })

      -- ✅ Stage / Commit / Push / Pull
      map("n", "<leader>gac", ":Git add %<CR>", { desc = "[G]it [A]dd [C]urrent File", silent = true })
      map("n", "<leader>gA", ":Git add .<CR>", { desc = "[G]it Add [A]ll", silent = true })
      map("n", "<leader>gc", ":Git commit<CR>", { desc = "[G]it [C]ommit", silent = true })
      map("n", "<leader>gp", ":Git push<CR>", { desc = "[G]it [P]ush", silent = true })
      map("n", "<leader>gP", ":Git pull<CR>", { desc = "[G]it [P]ull", silent = true })

      -- 🧾 Log
      map("n", "<leader>glg", ":Git log<CR>", { desc = "[G]it [L]o[G]", silent = true })

      -- 🌱 Branching
      map("n", "<leader>gcb", ":Git checkout -b ", { desc = "[G]it [C]reate [B]ranch" })
      map("n", "<leader>gco", ":Git checkout ", { desc = "[G]it [C]heckout Branch" })
      map("n", "<leader>gmb", ":Git merge ", { desc = "[G]it [M]erge [B]ranch" })
    end,
  },

  -- 🧩 Neogit + Diffview (Git UI + commit graph)
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
      map("n", "<leader>ggl", ":DiffviewLog<CR>", { desc = "[G]it [G]raph [L]og", silent = true })
      map("n", "<leader>ggd", ":DiffviewOpen<CR>", { desc = "[G]it [G]raph [D]iff", silent = true })
      map("n", "<leader>ggc", ":DiffviewClose<CR>", { desc = "[G]it [G]raph [C]lose", silent = true })
    end,
  },
}
--
--              Notes
-- 🧩 Plugin: lewis6991/gitsigns.nvim
-- 🔍 Git signs, hunk preview, blame
-- Keymap	desc	What It Does
-- <leader>gn	[G]it [N]ext Hunk	Jump to the next changed block (hunk) in the file
-- <leader>gp	[G]it [P]revious Hunk	Jump to the previous changed block (hunk)
-- <leader>gh	[G]it Preview [H]unk	Show a floating preview of the current hunk
-- <leader>gs	[G]it [S]tage Hunk	Stage the hunk under the cursor
-- <leader>gus	[G]it [U]ndo [S]tage	Undo a previously staged hunk
-- <leader>grh	[G]it [R]eset [H]unk	Reset the current hunk to original (unstage)
-- <leader>gsb	[G]it [S]tage [B]uffer	Stage all changes in the current buffer
-- <leader>glb	[G]it [L]ine [B]lame	Show who last changed the current line
-- <leader>gtb	[G]it [T]oggle [B]lame	Toggle line blame visibility on/off
-- <leader>gtd	[G]it [T]oggle [D]eleted	Show/hide deleted lines in diff
-- <leader>g1	Go to First Hunk	Jump to top of file and go to first hunk
-- <leader>g9	Go to Last Hunk	Jump to bottom of file and go to last hunk
-- 🧠 Plugin: tpope/vim-fugitive
-- Git CLI commands inside Neovim
-- Keymap	desc	What It Does
-- <leader>gS	[G]it [S]tatus	Opens Git status (like git status)
-- <leader>gds	[G]it [D]iff [S]plit	Split view with file diffs side-by-side
-- <leader>gb	[G]it [B]lame	Annotate each line with the last commit that changed it
-- <leader>gac	[G]it [A]dd [C]urrent	Stage the current file only
-- <leader>gA	[G]it Add [A]ll	Stage all modified files (git add .)
-- <leader>gc	[G]it [C]ommit	Commit staged changes
-- <leader>gp	[G]it [P]ush	Push commits to remote
-- <leader>gP	[G]it [P]ull	Pull latest commits from remote
-- <leader>glg	[G]it [L]o[G]	Show commit log in Neovim
-- <leader>gcb	[G]it [C]reate [B]ranch	Create a new branch (checkout -b)
-- <leader>gco	[G]it [C]heckout Branch	Switch to another branch
-- <leader>gmb	[G]it [M]erGe [B]ranch	Merge a branch into current one
-- 🖥️ Plugin: TimUntersberger/neogit + sindrets/diffview.nvim
-- Git UI, Commit Graph, Diff View (VS Code style)
-- Keymap	desc	What It Does
-- <leader>gg	[G]it [G]UI	Opens the Neogit UI (like VS Code Source Control)
-- <leader>ggl	[G]it Commit [G]raph [L]ogs	Visual commit history (graph view)
-- <leader>ggd	[G]it [G]ui [D]iff View	Full file diff viewer
-- <leader>ggc	[G]it [D]iff [C]lose	Close the diff viewer
