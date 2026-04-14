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
                    layout_config = {
                        horizontal = {
                            prompt_position = "top",
                            preview_width = 0.55,
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
            -- Keymaps
            -- =================================================================
            local map = vim.keymap.set

            -- Project Search
            map('n', '<leader>ff', function()
                builtin.find_files({ hidden = true })
            end, { desc = "Fast [F]ind [F]iles" })

            -- Global/Home Search (Optimized for Arch)
            map('n', '<leader>gf', function()
                builtin.find_files({
                    cwd = vim.env.HOME,
                    hidden = true,
                    find_command = {
                        "rg", "--files", "--hidden",
                        "-g", "!.git",
                        "-g", "!node_modules",
                        "-g", "!.cache"
                    },
                    prompt_title = "Global Search (Home)",
                })
            end, { desc = "Lightning [G]lobal [F]ind" })

            -- Grep & Refactor
            map('n', '<leader>fg', builtin.live_grep, { desc = "[F]ind by Live [G]rep" })
            map('n', '<leader>fb', builtin.buffers,   { desc = '[F]ind [B]uffers' })
            map('n', '<leader>f.', builtin.oldfiles,  { desc = '[R]ecent [F]iles' })
            map('n', '<leader>fr', builtin.resume,    { desc = '[F]inder [R]esume' })
            -- LSP integration (Optional but handy)
            map('n', '<leader>fs', builtin.lsp_document_symbols, { desc = '[F]ind [S]ymbols' })
        end,
    },
}
