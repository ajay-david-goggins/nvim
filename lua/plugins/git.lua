return {
    -- =========================================================================
    -- PLUGIN 1: gitsigns.nvim
    -- Shows signs in column, inline blame, hunk preview & staging
    -- =========================================================================
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("gitsigns").setup({

                signs = {
                    add          = { text = "+" },
                    change       = { text = "~" },
                    delete       = { text = "-" },
                    topdelete    = { text = "^" },
                    changedelete = { text = "/" },
                    untracked    = { text = "$" },
                },

                signcolumn = true,
                word_diff  = false, -- false: was hiding/wrapping diff text

                -- Inline blame at end of line: hash · author · date · message
                current_line_blame = true,
                current_line_blame_opts = {
                    virt_text         = true,
                    virt_text_pos     = "eol",
                    delay             = 300,
                    ignore_whitespace = true,
                },
                -- 8-char hash shown first
                current_line_blame_formatter = "<abbrev_sha> · <author> · <author_time:%d %b %Y> · <summary>",

                diff_opts = {
                    algorithm        = "myers",
                    internal         = true,
                    indent_heuristic = true,
                },

                on_attach = function(bufnr)
                    local gs  = package.loaded.gitsigns
                    local map = function(mode, lhs, rhs, desc)
                        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
                    end

                    -- Hunk Navigation
                    map("n", "]h",          gs.next_hunk,                            "[G]it Next [H]unk")
                    map("n", "[h",          gs.prev_hunk,                            "[G]it Prev [H]unk")
                    map("n", "<leader>hp",  gs.preview_hunk,                         "[H]unk [P]review")

                    -- Stage / Reset / Undo
                    map("n", "<leader>hs",  gs.stage_hunk,                           "[H]unk [S]tage")
                    map("v", "<leader>hs",  function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "[H]unk [S]tage (visual)")
                    map("n", "<leader>hu",  gs.undo_stage_hunk,                      "[H]unk [U]ndo stage")
                    map("n", "<leader>hr",  gs.reset_hunk,                           "[H]unk [R]eset")
                    map("n", "<leader>hR",  gs.reset_buffer,                         "[H]unk [R]eset buffer")
                    map("n", "<leader>hS",  gs.stage_buffer,                         "[H]unk [S]tage buffer")

                    -- Blame
                    map("n", "<leader>gb",  function() gs.blame_line({ full = true }) end, "[G]it [B]lame line")
                    map("n", "<leader>gib", gs.toggle_current_line_blame,            "[G]it [I]nline [B]lame toggle")

                    -- Diff
                    map("n", "<leader>gd",  gs.diffthis,                             "[G]it [D]iff this")
                    map("n", "<leader>gdl", function() gs.diffthis("~") end,         "[G]it [D]iff [L]ast commit")
                end,
            })
        end,
    },

    -- =========================================================================
    -- PLUGIN 2: vim-fugitive
    -- Git CLI — status, commit, push, pull, log, blame, branch, reset
    -- =========================================================================
    {
        "tpope/vim-fugitive",
        cmd  = { "Git", "G" },
        keys = { "<leader>g" },
        config = function()
            local map = vim.keymap.set
            local o   = function(desc) return { desc = desc, silent = true } end

            -- Status & Diff
            map("n", "<leader>gS",   ":Git<CR>",               o("[G]it [S]tatus"))
            map("n", "<leader>gds",  ":Gvdiffsplit<CR>",        o("[G]it [D]iff [S]plit"))

            -- Add
            map("n", "<leader>gaa",  ":Git add .<CR>",          o("[G]it [A]dd [A]ll"))
            map("n", "<leader>gac",  ":Git add %<CR>",          o("[G]it [A]dd [C]urrent"))

            -- Commit / Push / Pull
            map("n", "<leader>gcm",  ":Git commit<CR>",         o("[G]it [C]o[M]mit"))
            map("n", "<leader>gp",   ":Git push<CR>",           o("[G]it [P]ush"))
            map("n", "<leader>gP",   ":Git pull<CR>",           o("[G]it [P]ull"))

            -- Auto: add all + commit with branch name + push
            map("n", "<leader>gacp", function()
                local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")
                local msg    = branch .. " - published"
                vim.cmd("Git add .")
                vim.cmd("Git commit -m '" .. msg .. "'")
                vim.cmd("Git push -u origin HEAD")
                vim.notify("Pushed: " .. msg, vim.log.levels.INFO)
            end, o("[G]it [A]dd [C]ommit [P]ush (auto)"))

            -- Log
            map("n", "<leader>glg",  ":Git log --oneline<CR>",               o("[G]it [L]o[G]"))
            map("n", "<leader>ghl",  ":Git log --oneline --graph --all<CR>", o("[G]it [H]istory [L]og"))

            -- GitLens feature: all commits that touched the current file
            -- Opens location list, navigate ]q/[q, Enter to view diff
            map("n", "<leader>gfl", function()
                vim.cmd("0Gclog")
                vim.cmd("lopen")
            end, o("[G]it [F]ile [L]og (GitLens)"))

            -- Blame full file (8-char hash per line, Enter opens that commit)
            map("n", "<leader>gbl",  ":Git blame<CR>",          o("[G]it [B]lame [L]ine"))

            -- Branch
            map("n", "<leader>gcb",  ":Git checkout -b ",       { desc = "[G]it [C]reate [B]ranch" })
            map("n", "<leader>gco",  ":Git checkout ",          { desc = "[G]it [C]heck[O]ut" })
            map("n", "<leader>gmb",  ":Git merge ",             { desc = "[G]it [M]erge [B]ranch" })

            -- Sync fork
            map("n", "<leader>gsf",  ":!git pull upstream main --rebase<CR>", o("[G]it [S]ync [F]ork"))

            -- Revert commit (prompt for hash)
            map("n", "<leader>grc", function()
                local hash = vim.fn.input("Revert commit hash: ")
                if hash ~= "" then vim.cmd("Git revert " .. hash) end
            end, o("[G]it [R]evert [C]ommit"))

            -- Reset to commit (prompt for hash + mode)
            map("n", "<leader>grs", function()
                local hash = vim.fn.input("Reset to hash: ")
                local mode = vim.fn.input("Mode [soft/mixed/hard]: ")
                if hash ~= "" and mode ~= "" then
                    vim.cmd("!git reset --" .. mode .. " " .. hash)
                else
                    vim.notify("Reset cancelled", vim.log.levels.WARN)
                end
            end, o("[G]it [R]e[S]et to commit"))

            -- No wrap in git/fugitive buffers (was hiding text)
            vim.api.nvim_create_autocmd("FileType", {
                pattern  = { "fugitive", "git" },
                callback = function()
                    vim.opt_local.wrap      = false
                    vim.opt_local.linebreak = false
                end,
            })
        end,
    },
}

-- =============================================================================
-- KEYBIND CHEATSHEET
-- =============================================================================
--
-- gitsigns
-- ]h              [G]it Next [H]unk
-- [h              [G]it Prev [H]unk
-- <leader>hp      [H]unk [P]review
-- <leader>hs      [H]unk [S]tage            (normal + visual)
-- <leader>hu      [H]unk [U]ndo stage
-- <leader>hr      [H]unk [R]eset
-- <leader>hR      [H]unk [R]eset buffer
-- <leader>hS      [H]unk [S]tage buffer
-- <leader>gb      [G]it [B]lame line        (full popup: hash + author + body)
-- <leader>gib     [G]it [I]nline [B]lame    toggle on/off
-- <leader>gd      [G]it [D]iff this         vs index
-- <leader>gdl     [G]it [D]iff [L]ast       vs last commit (~)
--
-- vim-fugitive
-- <leader>gS      [G]it [S]tatus            (- to stage, cc to commit, q to quit)
-- <leader>gds     [G]it [D]iff [S]plit
-- <leader>gaa     [G]it [A]dd [A]ll
-- <leader>gac     [G]it [A]dd [C]urrent
-- <leader>gcm     [G]it [C]o[M]mit
-- <leader>gp      [G]it [P]ush
-- <leader>gP      [G]it [P]ull
-- <leader>gacp    [G]it [A]dd [C]ommit [P]ush (auto, branch name as message)
-- <leader>glg     [G]it [L]o[G]             oneline
-- <leader>ghl     [G]it [H]istory [L]og     project graph (--all)
-- <leader>gfl     [G]it [F]ile [L]og        GitLens: all commits for this file
--                                            location list, Enter = view diff
-- <leader>gbl     [G]it [B]lame [L]ine      full file, Enter opens commit
-- <leader>gcb     [G]it [C]reate [B]ranch
-- <leader>gco     [G]it [C]heck[O]ut
-- <leader>gmb     [G]it [M]erge [B]ranch
-- <leader>gsf     [G]it [S]ync [F]ork
-- <leader>grc     [G]it [R]evert [C]ommit   (prompt)
-- <leader>grs     [G]it [R]e[S]et           (prompt hash + soft/mixed/hard)
-- =============================================================================
