return {
    -----------------------------------------------------------------------------
    -- 🔍 Git signs, hunk preview & line blame
    -----------------------------------------------------------------------------
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
                word_diff = true,
                current_line_blame = true,
                current_line_blame_opts = {
                    delay = 100,
                    ignore_whitespace = true,
                },
                current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns
                    local map = function(mode, lhs, rhs, desc)
                        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
                    end

                    -- 🔁 Hunk navigation
                    map("n", "<leader>ghn", gs.next_hunk, "[G]it [N]ext [H]unk")
                    map("n", "<leader>ghp", gs.prev_hunk, "[G]it [P]revious [H]unk")
                    map("n", "<leader>gh", gs.preview_hunk, "[G]it Preview [H]unk")

                    -- 🔝 First/Last Hunk
                    map("n", "<leader>g1", function() vim.cmd("1") gs.next_hunk() end, "[G]o to First Hunk")
                    map("n", "<leader>g9", function() vim.cmd("normal G") gs.prev_hunk() end, "[G]o to Last Hunk")

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
                    map("n", "<leader>gdi", ":Gitsigns toggle_word_diff<CR>", "[G]it [D]iff [I]nline")
                end,
            })
        end,
    },

    -----------------------------------------------------------------------------
    -- 🧠 Git CLI Commands - Fugitive
    -----------------------------------------------------------------------------
    {
        "tpope/vim-fugitive",
        config = function()
            local map = vim.keymap.set

            -- 📄 Status, Diff, Blame
            map("n", "<leader>gS", ":Git<CR>", { desc = "[G]it [S]tatus", silent = true })
            map("n", "<leader>gds", ":Gvdiffsplit<CR>", { desc = "[G]it [D]iff [S]plit", silent = true })
            map("n", "<leader>gb", ":Git blame<CR>", { desc = "[G]it [B]lame", silent = true })

            -- ✅ Add, Commit, Push, Pull
            map("n", "<leader>gac", ":Git add %<CR>", { desc = "[G]it [A]dd [C]urrent", silent = true })
            map("n", "<leader>gaa", ":Git add .<CR>", { desc = "[G]it [A]dd [A]ll", silent = true })
            map("n", "<leader>gc", ":Git commit<CR>", { desc = "[G]it [C]ommit", silent = true })
            map("n", "<leader>gp", ":Git push<CR>", { desc = "[G]it [P]ush", silent = true })
            map("n", "<leader>gP", ":Git pull<CR>", { desc = "[G]it [P]ull", silent = true })

            map("n", "<leader>gacp", function()
                -- Get current branch name
                local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")
                local msg = branch .. " - published successfully 🚀"

                -- Git Add, Commit, Push with upstream
                vim.cmd("Git add .")
                vim.cmd("Git commit -m '" .. msg .. "'")
                vim.cmd("Git push -u origin HEAD")

                -- Notify user
                vim.notify("✅ Branch '" .. branch .. "' published with commit: " .. msg, vim.log.levels.INFO)
            end, { desc = "[G]it [A]dd + [C]ommit + [P]ush Auto", silent = true })

            -- 🔎 Logs
            map("n", "<leader>glg", ":Git log<CR>", { desc = "[G]it [L]o[G]", silent = true })

            -- 🌿 Branching
            map("n", "<leader>gcb", ":Git checkout -b ", { desc = "[G]it [C]reate [B]ranch" })
            map("n", "<leader>gco", ":Git checkout ", { desc = "[G]it [C]heck[o]ut", silent = true })
            map("n", "<leader>gmb", ":Git merge ", { desc = "[G]it [M]erge [B]ranch", silent = true })

            -- 🔁 Sync Fork
            map("n", "<leader>gsf", ":!git pull upstream main --rebase<CR>", { desc = "[G]it [S]ync [F]ork", silent = true })

            -- 🧨 Revert, Checkout or Reset to commit
            map("n", "<leader>grc", function()
                local hash = vim.fn.input("Revert Commit Hash: ")
                if hash ~= "" then vim.cmd("Git revert " .. hash) end
            end, { desc = "[G]it [R]evert [C]ommit", silent = true })

            map("n", "<leader>gcoh", function()
                local hash = vim.fn.input("Checkout Commit Hash: ")
                if hash ~= "" then vim.cmd("Git checkout " .. hash) end
            end, { desc = "[G]it [C]heck[o]ut [H]ash", silent = true })

            map("n", "<leader>grs", function()
                local hash = vim.fn.input("Reset To Hash: ")
                local mode = vim.fn.input("Mode (soft/mixed/hard): ")
                if hash ~= "" and mode ~= "" then
                    vim.cmd("!git reset --" .. mode .. " " .. hash)
                else
                    vim.notify("Reset cancelled", vim.log.levels.WARN)
                end
            end, { desc = "[G]it [R]e[S]et to Commit", silent = true })
        end,
    },

    -----------------------------------------------------------------------------
    -- 🖥️ Git UI - Neogit + Diffview (VS Code Style)
    -----------------------------------------------------------------------------
    {
        "TimUntersberger/neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "sindrets/diffview.nvim",
        },
        config = function()
            require("neogit").setup({
                integrations = { diffview = true },
            })
            local map = vim.keymap.set
            map("n", "<leader>gg", ":Neogit<CR>", { desc = "[G]it [G]UI", silent = true })
            map("n", "<leader>ggl", ":DiffviewLog<CR>", { desc = "[G]it [G]raph [L]og", silent = true })
            map("n", "<leader>ggd", ":DiffviewOpen<CR>", { desc = "[G]it [G]raph [D]iff", silent = true })
            map("n", "<leader>ggc", ":DiffviewClose<CR>", { desc = "[G]it [G]raph [C]lose", silent = true })
        end,
    },

    -----------------------------------------------------------------------------
    -- 🔍 Git Telescope Extensions (Branches + Status)
    -----------------------------------------------------------------------------
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local map = vim.keymap.set
            map("n", "<leader>gbc", "<cmd>Telescope git_branches<CR>", { desc = "[G]it [B]ranch [C]heckout" })
            map("n", "<leader>gcm", "<cmd>Telescope git_commits<CR>", { desc = "[G]it [C]o[M]mits" })
            map("n", "<leader>gfc", "<cmd>Telescope git_bcommits<CR>", { desc = "[G]it [F]ile [C]ommits" })
            map("n", "<leader>gst", "<cmd>Telescope git_status<CR>", { desc = "[G]it [S]tatus [T]elescope" })
        end,
    },

    -----------------------------------------------------------------------------
    -- 🧾 Flog Timeline View (Commit History)
    -----------------------------------------------------------------------------
    {
        "rbong/vim-flog",
        cmd = { "Flog", "Flogsplit" },
        dependencies = { "tpope/vim-fugitive" },
        config = function()
            vim.keymap.set("n", "<leader>gfh", ":Flog<CR>", { desc = "[G]it [F]log [H]istory", silent = true })
        end,
    },
}
--
-- 🔁 Git Signs (via gitsigns.nvim)
-- Keymap	Description
-- ghn	Git next hunk
-- ghp	Git previous hunk
-- gh	Git preview hunk
-- g1	Git go to first hunk
-- g9	Git go to last hunk
-- gs	Git stage hunk
-- gs (visual)	Git stage hunk (visual mode)
-- gus	Git undo stage hunk
-- grh	Git reset hunk
-- gsb	Git stage buffer
-- glb	Git line blame
-- gtb	Git toggle line blame
-- gtd	Git toggle deleted lines
-- gdi	Git diff inline toggle
-- 🧠 Core Git (via vim-fugitive)
-- Keymap	Description
-- gS	Git status
-- gds	Git diff split
-- gb	Git blame
-- gac	Git add current file
-- gA	Git add all files
-- gc	Git commit
-- gp	Git push
-- gP	Git pull
-- gacp	Git add + commit + push
-- glg	Git log
-- gcb	Git create branch
-- gco	Git checkout branch
-- gmb	Git merge branch
-- gsf	Git sync fork from upstream
-- grc	Git revert commit by hash
-- gcoh	Git checkout commit hash
-- grs	Git reset to commit (soft/mixed/hard)
-- 🖥️ Git UI & Graph (via neogit + diffview)
-- Keymap	Description
-- gg	Git UI (Neogit)
-- ggl	Git graph log view
-- ggd	Git diff view
-- ggc	Git diff close
-- 🔍 Telescope Git Commands
-- Keymap	Description
-- gbc	Git branch checkout (Telescope)
-- gcm	Git commits (global)
-- gfc	Git file commits (current buffer)
-- gst	Git status (Telescope)
-- 📜 Git Timeline (via vim-flog)
-- Keymap	Description
-- gfh	Git full history log (Flog)
