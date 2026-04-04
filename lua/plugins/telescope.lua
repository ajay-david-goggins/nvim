return {
    {
        'nvim-telescope/telescope.nvim',
        version = false, 
        dependencies = {
            'nvim-lua/plenary.nvim',
            -- ⚡ The Secret Sauce: FZF Native (Requires 'make' to be installed)
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }, -- another table for build setup like , make sure complike using the make
        },
        config = function()
            local telescope = require('telescope')
            local actions = require('telescope.actions')
            local builtin = require('telescope.builtin')
            local home_dir = vim.fn.getenv("HOME")

            telescope.setup({
                defaults = {
                    -- Use faster ripgrep configuration
                    vimgrep_arguments = {
                        "rg", "--color=never", "--no-heading", "--with-filename",
                        "--line-number", "--column", "--smart-case", "--hidden",
                        "--glob", "!**/.git/*" -- Exclude .git for speed
                    },
                    prompt_prefix = "🔍 ",
                    selection_caret = "👉 ",
                    sorting_strategy = "ascending",
                    layout_config = {
                        horizontal = {
                            prompt_position = "top", -- Best for "ascending"
                            preview_width = 0.55,
                        },
                    },
                    -- ⚡ Load the FZF Sorter for instant results
                    file_sorter = require("telescope.sorters").get_fzf_sorter,
                    generic_sorter = require("telescope.sorters").get_generic_sorter,

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
                    }
                }
            })

            -- Load extensions
            telescope.load_extension('fzf')

            -- ⚡ SPEED SEARCH: Find Files (Local)
            vim.keymap.set('n', '<leader>ff', function()
                builtin.find_files({ 
                    hidden = true, 
                    no_ignore = false 
                })
            end, { desc = "Fast [F]ind [F]iles" })

            -- ⚡ HOMESEARCH: Optimized to ignore junk
            vim.keymap.set('n', '<leader>gf', function()
                builtin.find_files({
                    cwd = home_dir,
                    hidden = true,
                    -- Add folders to ignore so root search doesn't lag
                    find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*", "--glob", "!**/node_modules/*", "--glob", "!**/.cache/*" },
                    prompt_title = "Global Search (Home Optimized)",
                })
            end, { desc = "Lightning [G]lobal [F]ind Search" })

            -- ⚡ LIVE GREP (Local)
            vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "[F]ind by Live [G]rep" })

            -- Other keymaps...
            vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = '[F]ind [B]uffers' })
            vim.keymap.set('n', '<leader>f.', builtin.oldfiles, { desc = '[R]ecent [F]iles' })
            vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]inder [R]esume' })
        end,
    },
    {
        'nvim-telescope/telescope-ui-select.nvim',
        config = function()
            require("telescope").setup({
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown {}
                    }
                }
            })
            require("telescope").load_extension("ui-select")
        end,
    },
}
