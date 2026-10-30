-- =============================================================================
-- git.lua  ·  gitsigns.nvim + vim-fugitive + diffview.nvim (GitLens Pro)
-- =============================================================================

-- Shared helper: resolve the commit hash that last touched the CURRENT line
-- of the CURRENT file, via `git blame --porcelain` (works even without
-- gitsigns' internal API, so it's stable across gitsigns versions).
local function get_commit_hash_at_line()
    local file = vim.fn.expand("%:p")
    local line = vim.fn.line(".")
    if file == "" or vim.bo.buftype ~= "" then
        return nil
    end
    local result = vim.fn.systemlist(
        string.format("git blame -L %d,%d --porcelain -- %s", line, line, vim.fn.shellescape(file))
    )
    if vim.v.shell_error ~= 0 or #result == 0 then
        return nil
    end
    local hash = result[1]:match("^(%x+)")
    if not hash or hash:match("^0+$") then
        return nil -- uncommitted / working-tree line
    end
    return hash
end

return {
    -- =========================================================================
    -- PLUGIN 1: gitsigns.nvim
    -- Shows signs in column, inline blame, hunk preview & staging
    -- =========================================================================
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            -- Transparent smudge hook for git-crypt encrypted repositories:
            local ok_repo, git_repo = pcall(require, "gitsigns.git.repo")
            if ok_repo and git_repo and git_repo.get_show_text then
                local orig_get_show_text = git_repo.get_show_text
                git_repo.get_show_text = function(self, object, encoding)
                    local stdout, stderr = orig_get_show_text(self, object, encoding)
                    if stdout and stdout[1] and stdout[1]:find("GITCRYPT") then
                        local raw = table.concat(stdout, "\n")
                        local res = vim.system({ "git-crypt", "smudge" }, { stdin = raw, cwd = self.toplevel }):wait()
                        if res.code == 0 and res.stdout then
                            stdout = vim.split(res.stdout, "\n", { plain = true })
                            if #stdout > 0 and stdout[#stdout] == "" then
                                stdout[#stdout] = nil
                            end
                        end
                    end
                    return stdout, stderr
                end
            end

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
                word_diff  = false,

                -- Inline blame at end of line: hash · author · date · message
                current_line_blame = true,
                current_line_blame_opts = {
                    virt_text         = true,
                    virt_text_pos     = "eol",
                    delay             = 300,
                    ignore_whitespace = true,
                },
                current_line_blame_formatter = "<abbrev_sha> · <author> · <author_time:%d %b %Y> · <summary>",

                diff_opts = {
                    algorithm                       = "myers",
                    internal                        = true,
                    indent_heuristic                = true,
                    ignore_whitespace_change_at_eol = true,
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
                    map("n", "<leader>hs",  gs.stage_hunk,                            "[H]unk [S]tage")
                    map("v", "<leader>hs",  function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "[H]unk [S]tage (visual)")
                    map("n", "<leader>hu",  gs.undo_stage_hunk,                      "[H]unk [U]ndo stage")
                    map("n", "<leader>hr",  gs.reset_hunk,                           "[H]unk [R]eset")
                    map("n", "<leader>hR",  gs.reset_buffer,                         "[H]unk [R]eset buffer")
                    map("n", "<leader>hS",  gs.stage_buffer,                         "[H]unk [S]tage buffer")

                    -- Blame
                    map("n", "<leader>gb",  function() gs.blame_line({ full = true }) end, "[G]it [B]lame line")
                    map("n", "<leader>gib", gs.toggle_current_line_blame,            "[G]it [I]nline [B]lame toggle")

                    -- Quick diff vs index / last commit
                    map("n", "<leader>gd",  gs.diffthis,                             "[G]it [D]iff this")
                    map("n", "<leader>gdl", function() gs.diffthis("~") end,         "[G]it [D]iff [L]ast commit")

                    -- =================================================================
                    -- 🌟 GitLens: Yank commit hash of current line to clipboard
                    -- =================================================================
                    map("n", "<leader>gyc", function()
                        local hash = get_commit_hash_at_line()
                        if not hash then
                            vim.notify("No commit for this line (uncommitted or new line)", vim.log.levels.WARN)
                            return
                        end
                        vim.fn.setreg("+", hash)
                        vim.notify("󰆏  Copied commit " .. hash:sub(1, 8) .. " to clipboard", vim.log.levels.INFO)
                    end, "[G]it [Y]ank [C]ommit hash to clipboard")
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
        cmd  = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gedit" },
        keys = {
            { "<leader>gS", desc = "[G]it [S]tatus" },
            { "<leader>gcm", desc = "[G]it [C]o[M]mit" },
            { "<leader>gp", desc = "[G]it [P]ush" },
            { "<leader>gP", desc = "[G]it [P]ull" },
        },
        config = function()
            local map = vim.keymap.set
            local o   = function(desc) return { desc = desc, silent = true } end

            -- Status & Diff Split
            map("n", "<leader>gS",   ":Git<CR>",                o("[G]it [S]tatus"))
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

            -- Log (simple oneline terminal view)
            map("n", "<leader>glg",  ":Git log --oneline<CR>",  o("[G]it [L]o[G] (oneline)"))

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

            -- No wrap in git/fugitive buffers
            vim.api.nvim_create_autocmd("FileType", {
                pattern  = { "fugitive", "git" },
                callback = function()
                    vim.opt_local.wrap      = false
                    vim.opt_local.linebreak = false
                end,
            })
        end,
    },

    -- =========================================================================
    -- PLUGIN 3: diffview.nvim (GitLens Pro for Neovim)
    -- nvim-tree style left sidebar + VS Code 2-window side-by-side diff.
    -- Single keypress (<leader>q or q) closes all 3 windows completely.
    -- =========================================================================
    {
        "sindrets/diffview.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
        cmd = {
            "DiffviewOpen",
            "DiffviewClose",
            "DiffviewToggleFiles",
            "DiffviewFocusFiles",
            "DiffviewFileHistory",
            "DiffviewRefresh",
        },
        keys = {
            -- 1. Working tree double-window diff (VS Code source control style)
            { "<leader>gdo", "<cmd>DiffviewOpen<CR>", desc = "[G]it [D]iffview [O]pen (working tree diff)" },
            { "<leader>gdc", "<cmd>DiffviewClose<CR>", desc = "[G]it [D]iffview [C]lose" },

            -- 2. Single file commit history (left sidebar like nvim-tree + side-by-side diff)
            {
                "<leader>gfl",
                function()
                    local file = vim.fn.expand("%:p")
                    if file == "" or vim.bo.buftype ~= "" then
                        vim.notify("No file in current buffer", vim.log.levels.WARN)
                        return
                    end
                    vim.cmd("DiffviewFileHistory %")
                end,
                desc = "[G]it [F]ile [L]og (single file history in left sidebar & side-by-side diff)",
            },
            {
                "<leader>glf",
                function()
                    local file = vim.fn.expand("%:p")
                    if file == "" or vim.bo.buftype ~= "" then
                        vim.notify("No file in current buffer", vim.log.levels.WARN)
                        return
                    end
                    vim.cmd("DiffviewFileHistory %")
                end,
                desc = "[G]it [L]og of [F]ile (alias for <leader>gfl)",
            },

            -- 3. Whole branch / repo commit history with graph, commit folds, and affected file stats
            {
                "<leader>ghl",
                "<cmd>DiffviewFileHistory<CR>",
                desc = "[G]it [H]istory [L]og (branch history with affected files list & diffs)",
            },

            -- 4. Commit Inspector: entered commit -> affected files tree -> select to view side-by-side diff
            {
                "<leader>gci",
                function()
                    local line_hash = get_commit_hash_at_line()
                    local prompt_text = (line_hash and line_hash ~= "")
                            and string.format("Inspect commit hash [%s]: ", line_hash:sub(1, 8))
                        or "Inspect commit hash (default HEAD): "
                    local hash = vim.fn.input(prompt_text)
                    if hash == "" then
                        hash = (line_hash and line_hash ~= "") and line_hash or "HEAD"
                    end
                    if hash == "" then
                        vim.notify("No commit hash provided", vim.log.levels.WARN)
                        return
                    end
                    vim.cmd(string.format("DiffviewOpen %s^!", hash))
                end,
                desc = "[G]it [C]ommit [I]nspect (enter hash -> affected files -> side-by-side diff)",
            },
            {
                "<leader>gch",
                function()
                    local line_hash = get_commit_hash_at_line()
                    local prompt_text = (line_hash and line_hash ~= "")
                            and string.format("Inspect commit hash [%s]: ", line_hash:sub(1, 8))
                        or "Inspect commit hash (default HEAD): "
                    local hash = vim.fn.input(prompt_text)
                    if hash == "" then
                        hash = (line_hash and line_hash ~= "") and line_hash or "HEAD"
                    end
                    if hash == "" then
                        vim.notify("No commit hash provided", vim.log.levels.WARN)
                        return
                    end
                    vim.cmd(string.format("DiffviewOpen %s^!", hash))
                end,
                desc = "[G]it [C]ommit [H]ash inspect (alias for <leader>gci)",
            },
        },
        config = function()
            local actions = require("diffview.actions")

            require("diffview").setup({
                diff_opts = {
                    mode = "stage",
                },
                enhanced_diff_hl = true,
                use_icons = true,
                icons = {
                    folder_closed = "",
                    folder_open = "",
                },
                signs = {
                    fold_closed = "",
                    fold_open = "",
                    done = "✓",
                },
                view = {
                    default = {
                        layout = "diff2_horizontal", -- VS Code style 2-window horizontal side-by-side split
                        winbar_info = true,
                    },
                    merge_tool = {
                        layout = "diff3_horizontal",
                        disable_diagnostics = true,
                        winbar_info = true,
                    },
                    file_history = {
                        layout = "diff2_horizontal", -- VS Code style 2-window horizontal side-by-side split
                        winbar_info = true,
                    },
                },
                file_panel = {
                    listing_style = "tree",
                    tree_options = {
                        flatten_dirs = true,
                        folder_statuses = "only_folded",
                    },
                    win_config = {
                        position = "left", -- nvim-tree style left sidebar
                        width = 40,
                    },
                },
                file_history_panel = {
                    log_options = {
                        git = {
                            single_file = {
                                diff_merges = "first-parent",
                                follow = true,
                            },
                            multi_file = {
                                diff_merges = "first-parent",
                            },
                        },
                    },
                    win_config = {
                        position = "left", -- nvim-tree style left sidebar
                        width = 42,
                    },
                },
                hooks = {
                    diff_buf_read = function(bufnr)
                        vim.keymap.set("n", "<leader>q", "<cmd>DiffviewClose<CR>", { buffer = bufnr, silent = true, desc = "Close entire Diffview" })
                        vim.keymap.set("n", "q", "<cmd>DiffviewClose<CR>", { buffer = bufnr, silent = true, desc = "Close entire Diffview" })
                    end,
                },
                keymaps = {
                    disable_defaults = false,
                    view = {
                        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview (all 3 windows in 1 shot)" } },
                        { "n", "<leader>q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview (all 3 windows in 1 shot)" } },
                        { "n", "<tab>", actions.select_next_entry, { desc = "Open next file diff" } },
                        { "n", "<s-tab>", actions.select_prev_entry, { desc = "Open previous file diff" } },
                        { "n", "gf", actions.goto_file_edit, { desc = "Jump to file in previous window" } },
                    },
                    file_panel = {
                        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview (all 3 windows in 1 shot)" } },
                        { "n", "<leader>q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview (all 3 windows in 1 shot)" } },
                        { "n", "j", actions.next_entry, { desc = "Next file" } },
                        { "n", "k", actions.prev_entry, { desc = "Previous file" } },
                        { "n", "<cr>", actions.select_entry, { desc = "Open diff for file" } },
                        { "n", "o", actions.select_entry, { desc = "Open diff for file" } },
                        { "n", "R", actions.refresh_files, { desc = "Refresh files" } },
                        { "n", "<tab>", actions.select_next_entry, { desc = "Next file diff" } },
                        { "n", "<s-tab>", actions.select_prev_entry, { desc = "Previous file diff" } },
                        { "n", "gf", actions.goto_file_edit, { desc = "Open file in editor" } },
                    },
                    file_history_panel = {
                        { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview (all 3 windows in 1 shot)" } },
                        { "n", "<leader>q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview (all 3 windows in 1 shot)" } },
                        { "n", "j", actions.next_entry, { desc = "Next commit / file" } },
                        { "n", "k", actions.prev_entry, { desc = "Previous commit / file" } },
                        { "n", "<cr>", actions.select_entry, { desc = "Open side-by-side diff / toggle commit files" } },
                        { "n", "o", actions.select_entry, { desc = "Open side-by-side diff / toggle commit files" } },
                        -- Fold / unfold affected files under each commit with diff stats (+/-)
                        { "n", "<space>", actions.toggle_fold, { desc = "Toggle commit affected files list" } },
                        { "n", "za", actions.toggle_fold, { desc = "Toggle commit affected files list" } },
                        { "n", "zo", actions.open_fold, { desc = "Expand commit affected files" } },
                        { "n", "zc", actions.close_fold, { desc = "Collapse commit affected files" } },
                        { "n", "zR", actions.open_all_folds, { desc = "Expand all commits affected files" } },
                        { "n", "zM", actions.close_all_folds, { desc = "Collapse all commits affected files" } },
                        { "n", "y", actions.copy_hash, { desc = "Copy commit hash to clipboard" } },
                        -- Open full commit in diffview tree
                        { "n", "O", actions.open_in_diffview, { desc = "Open all affected files in full Diffview" } },
                        { "n", "<C-d>", actions.open_in_diffview, { desc = "Open all affected files in full Diffview" } },
                        { "n", "gf", actions.goto_file_edit, { desc = "Open file in editor" } },
                        { "n", "g!", actions.options, { desc = "Open options panel" } },
                    },
                },
            })
        end,
    },
}

-- =============================================================================
-- KEYBIND CHEATSHEET (GitLens Pro + Git Tools)
-- =============================================================================
--
-- GitLens Pro (diffview.nvim) — Left Sidebar (nvim-tree style) + 2-Window Split Diff:
-- <leader>gfl / <leader>glf  Single file commit history
--                            * Left sidebar shows commits list with author, date, message
--                            * Main area shows VS Code 2-window side-by-side diff (old vs new)
--                            * Sidebar stays open when selecting commits (<CR> / o)
--                            * Press 'O' or '<C-d>' to show all affected files in that commit
--                            * Press 'y' to copy commit hash
--                            * Press 'q' or '<leader>q' to close ALL 3 windows in one shot!
--
-- <leader>ghl                Branch / project commit history
--                            * Left sidebar shows commits list
--                            * Press <Space> or za on any commit to expand affected files with stats (+adds, -dels)
--                            * Select any file with <CR> to show its side-by-side diff
--                            * Press 'q' or '<leader>q' to close ALL 3 windows in one shot!
--
-- <leader>gci / <leader>gch  Commit Inspector
--                            * Prompt SHA (defaults to current line commit), opens all affected files
--                            * Selecting any file opens side-by-side diff
--
-- <leader>gdo                Working tree side-by-side diff (all uncommitted changes)
-- <leader>gdc                Close Diffview (also 'q' or '<leader>q' inside Diffview)
--
-- gitsigns.nvim:
-- ]h / [h                    Next / Prev hunk
-- <leader>hp                 Hunk preview popup
-- <leader>hs / <leader>hr    Hunk stage / reset
-- <leader>hS / <leader>hR    Buffer stage / reset
-- <leader>hu                 Undo hunk stage
-- <leader>gb                 Blame line popup (details)
-- <leader>gib                Toggle inline blame on/off
-- <leader>gd / <leader>gdl   Quick diff vs index / last commit
-- <leader>gyc                Yank commit hash of current line to clipboard
--
-- vim-fugitive & lazygit:
-- <leader>lg                 Open LazyGit floating UI (pressing 'o' or 'e' opens file in this nvim instance!)
-- <leader>gS                 Git status summary
-- <leader>gds                Fugitive diff split
-- <leader>gaa / <leader>gac  Git add all / Git add current
-- <leader>gcm                Git commit
-- <leader>gp / <leader>gP    Git push / Git pull
-- <leader>gacp               Git auto add + commit + push
-- <leader>gbl                Git blame full buffer
-- <leader>gcb / <leader>gco  Git checkout -b / Git checkout
-- <leader>gmb                Git merge branch
-- <leader>gsf                Sync upstream main fork
-- <leader>grc / <leader>grs  Revert commit / Reset to commit
-- =============================================================================
