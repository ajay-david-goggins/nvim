-- =============================================================================
-- git.lua  ·  gitsigns.nvim + vim-fugitive + GitLens-style extras
-- =============================================================================

-- Shared helper: resolve the commit hash that last touched the CURRENT line
-- of the CURRENT file, via `git blame --porcelain` (works even without
-- gitsigns' internal API, so it's stable across gitsigns versions).
local function get_commit_hash_at_line()
    local file = vim.fn.expand("%:p")
    local line = vim.fn.line(".")
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
                    map("n", "<leader>hs",  gs.stage_hunk,                            "[H]unk [S]tage")
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

                    -- =================================================================
                    -- 🌟 GitLens: Yank commit hash of current line
                    -- =================================================================
                    map("n", "<leader>gyc", function()
                        local hash = get_commit_hash_at_line()
                        if not hash then
                            vim.notify("No commit for this line (uncommitted)", vim.log.levels.WARN)
                            return
                        end
                        vim.fn.setreg("+", hash)
                        vim.notify("󰆏  Copied commit " .. hash:sub(1, 8) .. " to clipboard", vim.log.levels.INFO)
                    end, "[G]it [Y]ank [C]ommit hash")

                    -- =================================================================
                    -- 🌟 GitLens: Commit & File Inspector for current line
                    -- Shows full commit message/metadata + every file touched in
                    -- that commit. Press <CR> on a file line to view its diff.
                    -- Press q to close.
                    -- =================================================================
                    map("n", "<leader>gci", function()
                        local hash = get_commit_hash_at_line()
                        if not hash then
                            vim.notify("No commit for this line (uncommitted)", vim.log.levels.WARN)
                            return
                        end

                        local meta = vim.fn.systemlist(string.format(
                            "git show -s --format='commit %%H%%nAuthor: %%an <%%ae>%%nDate:   %%ad%%n%%n    %%s%%n%%n%%b' %s",
                            hash
                        ))
                        local stat = vim.fn.systemlist(
                            string.format("git show --stat --format='' %s", hash)
                        )

                        local lines = {}
                        vim.list_extend(lines, meta)
                        table.insert(lines, "")
                        table.insert(lines, "── Files changed in this commit (<CR> to diff, q to close) ──")
                        vim.list_extend(lines, stat)

                        local buf = vim.api.nvim_create_buf(false, true)
                        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                        vim.bo[buf].filetype   = "git"
                        vim.bo[buf].bufhidden  = "wipe"
                        vim.bo[buf].modifiable = false

                        local width  = math.floor(vim.o.columns * 0.8)
                        local height = math.floor(vim.o.lines * 0.8)
                        local win = vim.api.nvim_open_win(buf, true, {
                            relative  = "editor",
                            width     = width,
                            height    = height,
                            row       = math.floor((vim.o.lines - height) / 2),
                            col       = math.floor((vim.o.columns - width) / 2),
                            border    = "rounded",
                            title     = " Commit Inspector · " .. hash:sub(1, 8) .. " ",
                            title_pos = "center",
                        })

                        vim.keymap.set("n", "<CR>", function()
                            local cur = vim.api.nvim_get_current_line()
                            local file = cur:match("^%s*(.-)%s+|")
                            if not file or file == "" then return end
                            vim.api.nvim_win_close(win, true)
                            vim.cmd("tabnew")
                            vim.cmd("Git show " .. hash .. " -- " .. vim.fn.fnameescape(file))
                        end, { buffer = buf, silent = true, desc = "Open diff for file under cursor" })

                        vim.keymap.set("n", "q", function()
                            if vim.api.nvim_win_is_valid(win) then
                                vim.api.nvim_win_close(win, true)
                            end
                        end, { buffer = buf, silent = true })
                    end, "[G]it [C]ommit [I]nspector (GitLens)")
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

            -- =================================================================
            -- 🌟 GitLens: Global commit hash inspection (prompt for any SHA)
            -- =================================================================
            map("n", "<leader>gch", function()
                local hash = vim.fn.input("Inspect commit hash: ")
                if hash ~= "" then
                    vim.cmd("Git show " .. hash)
                else
                    vim.notify("Commit inspection cancelled", vim.log.levels.WARN)
                end
            end, o("[G]it [C]ommit [H]ash inspect (GitLens)"))

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
-- <leader>gyc     [G]it [Y]ank [C]ommit     hash of current line → clipboard (GitLens)
-- <leader>gci     [G]it [C]ommit [I]nspector current line: message + metadata +
--                                           all files in that commit, <CR>=diff file, q=close (GitLens)
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
--                                           location list, Enter = view diff
-- <leader>gbl     [G]it [B]lame [L]ine      full file, Enter opens commit
-- <leader>gcb     [G]it [C]reate [B]ranch
-- <leader>gco     [G]it [C]heck[O]ut
-- <leader>gmb     [G]it [M]erge [B]ranch
-- <leader>gsf     [G]it [S]ync [F]ork
-- <leader>grc     [G]it [R]evert [C]ommit   (prompt)
-- <leader>grs     [G]it [R]e[S]et           (prompt hash + soft/mixed/hard)
-- <leader>gch     [G]it [C]ommit [H]ash inspect (prompt any SHA, GitLens)
-- =============================================================================
