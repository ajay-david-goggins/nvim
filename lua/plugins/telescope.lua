return {
    {
        'nvim-telescope/telescope.nvim',
        version = false, -- Use latest for 0.13 compatibility
        dependencies = {
            'nvim-lua/plenary.nvim',
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
            'nvim-telescope/telescope-ui-select.nvim',
        },
        config = function()
            local telescope = require('telescope')
            local actions = require('telescope.actions')
            local builtin = require('telescope.builtin')

            telescope.setup({
                defaults = {
                    -- Behind the scenes: ripgrep handles the heavy lifting
                    vimgrep_arguments = {
                        "rg",
                        "--color=never",
                        "--no-heading",
                        "--with-filename",
                        "--line-number",
                        "--column",
                        "--smart-case",
                        "--hidden",
                        "--glob", "!**/.git/*",
                    },
                    prompt_prefix = "🔍 ",
                    selection_caret = "👉 ",
                    sorting_strategy = "ascending",
                    -- Long paths (deep monorepo trees, etc.) truncate with an
                    -- ellipsis from the left instead of wrapping onto a
                    -- second line in the results window -- wrapping there
                    -- pushes every other row down and makes the list jump
                    -- around as you move the selection.
                    wrap_results = true,
                    -- Folders/files that clutter every project search and
                    -- you never actually want a hit inside. Applies to
                    -- find_files, live_grep, grep_string -- everything that
                    -- shares `defaults`. Add more patterns here as needed.
                    -- file_ignore_patterns = {
                    --     "%.git/",
                    --     "node_modules/",
                    --     "dist/",
                    --     "build/",
                    --     "vendor/",
                    --     "target/",
                    --     "__pycache__/",
                    --     "%.venv/",
                    --     "venv/",
                    --     "%.next/",
                    --     "%.cache/",
                    --     "coverage/",
                    --     "%.lock$",
                    --     "package%-lock%.json",
                    --     "yarn%.lock",
                    --     "%.min%.js$",
                    --     "%.min%.css$",
                    -- },
                    layout_config = {
                        horizontal = {
                            prompt_position = "top",
                            preview_width = 0.45,
                        },
                    },
                    mappings = {
                        i = {
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                            ["<C-l>"] = actions.select_default,
                            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                        },
                    },
                },
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({})
                    }
                }
            })

            -- Load extensions
            telescope.load_extension('fzf')
            telescope.load_extension('ui-select')

            -- =================================================================
            -- Root detection (§5)
            -- =================================================================
            -- Project root = nearest ancestor of the CURRENT BUFFER containing
            -- any of these markers. vim.fs.root walks upward and stops at the
            -- first match — this is the built-in Neovim 0.10+ replacement for
            -- hand-rolled root-finding, no plugin needed.
            local root_markers = {
                ".git", "package.json", "pyproject.toml", "setup.cfg",
                "Cargo.toml", "go.mod", "Makefile",
            }

            local function project_root()
                local buf_path = vim.api.nvim_buf_get_name(0)
                local root = vim.fs.root(buf_path ~= "" and buf_path or 0, root_markers)
                return root or vim.fn.getcwd() -- fall back to cwd, never error
            end

            -- =================================================================
            -- Keymaps
            -- =================================================================
            local map = vim.keymap.set

            -- -----------------------------------------------------------------
            -- <leader>f  LOCAL search — nvim's cwd (where you started nvim),
            -- or the current buffer's own directory. Fast, no root detection.
            -- -----------------------------------------------------------------
            map('n', '<leader>ff', function()
                builtin.find_files({ hidden = true })
            end, { desc = "[F]ind [F]iles (cwd)" })

            map('n', '<leader>fg', function()
                builtin.live_grep({ cwd = vim.fn.getcwd() })
            end, { desc = "[F]ind [G]rep (cwd)" })

            map('n', '<leader>fc', function()
                local buf_dir = vim.fn.expand('%:p:h')
                builtin.find_files({ hidden = true, cwd = buf_dir, prompt_title = "Files in " .. buf_dir })
            end, { desc = "[F]ind in [C]urrent buffer's dir" })

            map('n', '<leader>fb', builtin.buffers,   { desc = '[F]ind [B]uffers' })
            map('n', '<leader>fr', builtin.resume,    { desc = '[F]inder [R]esume' })
            map('n', '<leader>fs', builtin.lsp_document_symbols, { desc = '[F]ind [S]ymbols (buffer)' })
            map('n', '<leader>fd', function()
                builtin.diagnostics({ bufnr = 0 })
            end, { desc = '[F]ind [D]iagnostics (buffer)' })

            -- -----------------------------------------------------------------
            -- Recent files (§: oldfiles was showing stale/unrelated entries)
            --
            -- builtin.oldfiles just lists vim.v.oldfiles as-is: every file
            -- Neovim has EVER opened across EVERY project on this machine,
            -- including ones that have since been deleted or moved. That's
            -- exactly the "sometimes shows unexpected stuff" symptom -- it's
            -- not scoped to the current project and never checks the file
            -- still exists.
            --
            -- This custom picker filters vim.v.oldfiles down to files that
            -- (a) are still on disk right now, and (b) live under the
            -- current project root -- before Telescope ever sees them.
            -- -----------------------------------------------------------------
            map('n', '<leader>f.', function()
                local root = project_root()
                local results = {}
                local seen = {}
                for _, file in ipairs(vim.v.oldfiles) do
                    local abs = vim.fn.fnamemodify(file, ':p')
                    if not seen[abs]
                        and abs:sub(1, #root) == root
                        and vim.loop.fs_stat(abs) ~= nil
                    then
                        seen[abs] = true
                        table.insert(results, abs)
                    end
                end

                require('telescope.pickers').new({}, {
                    prompt_title = 'Recent Files (project, existing only)',
                    finder = require('telescope.finders').new_table({
                        results = results,
                        entry_maker = function(entry)
                            return {
                                value = entry,
                                display = vim.fn.fnamemodify(entry, ':.'),
                                ordinal = entry,
                                path = entry,
                            }
                        end,
                    }),
                    sorter = require('telescope.config').values.file_sorter({}),
                    previewer = require('telescope.config').values.file_previewer({}),
                }):find()
            end, { desc = '[F]ind Recent [.]files (project, existing only)' })

            -- The old, unfiltered behaviour is still available if you
            -- genuinely want every file Neovim has ever touched, anywhere.
            map('n', '<leader>fO', builtin.oldfiles, { desc = '[F]ind [O]ldfiles (unfiltered, all projects)' })

            -- -----------------------------------------------------------------
            -- Find/grep restricted to one file type -- prompts for an
            -- extension first (e.g. "lua", "go", "tsx"), then searches only
            -- that type. Use when you know exactly what kind of file you're
            -- after and want to cut everything else out of the results.
            -- -----------------------------------------------------------------
            map('n', '<leader>ft', function()
                vim.ui.input({ prompt = 'File type (extension, e.g. lua/go/tsx): ' }, function(ext)
                    if not ext or ext == '' then return end
                    ext = ext:gsub('^%.', '') -- tolerate a leading dot
                    builtin.find_files({
                        cwd = project_root(),
                        hidden = true,
                        find_command = { 'rg', '--files', '--hidden', '--glob', '!**/.git/*', '--glob', '*.' .. ext },
                        prompt_title = 'Find *.' .. ext .. ' files',
                    })
                end)
            end, { desc = '[F]ind by file [T]ype' })

            map('n', '<leader>gt', function()
                vim.ui.input({ prompt = 'Grep in file type (extension, e.g. lua/go/tsx): ' }, function(ext)
                    if not ext or ext == '' then return end
                    ext = ext:gsub('^%.', '')
                    -- type_filter is telescope's native hook straight into
                    -- ripgrep's --type-add/--type, no manual glob needed.
                    builtin.live_grep({
                        cwd = project_root(),
                        type_filter = ext,
                        prompt_title = 'Grep *.' .. ext .. ' files',
                    })
                end)
            end, { desc = '[G]rep by file [T]ype' })

            -- -----------------------------------------------------------------
            -- <leader>s  GLOBAL/PROJECT search — root auto-detected via
            -- root_markers above, regardless of which nested dir you're in.
            -- -----------------------------------------------------------------
            map('n', '<leader>sf', function()
                local root = project_root()
                -- Prefer git_files inside a repo: faster, honors .gitignore
                -- natively. Falls back to find_files for non-git projects.
                if vim.fn.isdirectory(root .. "/.git") == 1 then
                    builtin.git_files({ cwd = root, show_untracked = true })
                else
                    builtin.find_files({ cwd = root, hidden = true })
                end
            end, { desc = "[S]earch [F]iles (project root)" })

            map('n', '<leader>sg', function()
                builtin.live_grep({ cwd = project_root() })
            end, { desc = "[S]earch [G]rep (project root)" })

            map('n', '<leader>sw', function()
                builtin.grep_string({ cwd = project_root() })
            end, { desc = "[S]earch [W]ord under cursor (project root)" })

            map('n', '<leader>sb', builtin.buffers, { desc = '[S]earch [B]uffers (all open)' })

            map('n', '<leader>ss', function()
                builtin.lsp_workspace_symbols({ cwd = project_root() })
            end, { desc = "[S]earch [S]ymbols (workspace)" })

            map('n', '<leader>sd', function()
                builtin.diagnostics({})
            end, { desc = "[S]earch [D]iagnostics (workspace)" })

            map('n', '<leader>sc', function()
                builtin.git_commits({ cwd = project_root() })
            end, { desc = "[S]earch [C]ommits (project root)" })
        end,
    },
}
