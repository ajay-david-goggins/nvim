return {
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.6',
        dependencies = {
            'nvim-lua/plenary.nvim'
        },
        config = function()
            local builtin = require('telescope.builtin')
            local actions = require("telescope.actions")
            local home_dir = vim.fn.getenv("HOME") -- typically /root in WSL

            -- Set up Telescope
            require("telescope").setup({
                defaults = {
                    prompt_prefix = "🔍 ",
                    selection_caret = "👉 ",
                    sorting_strategy = "ascending",
                    winblend = 5,
                    layout_strategy = "horizontal",
                    layout_config = {
                        horizontal = {
                            preview_width = 0.55,
                        },
                    },
                    preview = {
                        hide_on_startup = false,
                    },
                    mappings = {
                        i = {
                            ["<C-n>"] = actions.cycle_history_next,
                            ["<C-p>"] = actions.cycle_history_prev,
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                            ["<C-l>"] = actions.select_default, 
                        }
                    }
                }
            })

            -- Enable line numbers in preview pane
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "TelescopePreview",
                callback = function()
                    vim.wo.number = true
                    vim.wo.relativenumber = true
                end,
            })

            -- Mappings
            vim.keymap.set('n', '<leader>ff', function()
                builtin.find_files({ hidden = true })
            end, { desc = "[F]ind [F]iles (local + dotfiles)" })

            vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "[F]ind by [G]rep (local)" })

            vim.keymap.set('n', '<leader>gf', function()
                builtin.find_files({
                    cwd = home_dir,
                    hidden = true,
                    prompt_title = "Global File Search (/root)"
                })
            end, { desc = "[G]lobal [F]ile search (with dotfiles)" })

            vim.keymap.set('n', '<leader>ggf', function()
                builtin.live_grep({
                    cwd = home_dir,
                    prompt_title = "Global Grep Search (/root)"
                })
            end, { desc = "[G]lobal [G]rep [F]ind" })

            vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = '[F]ind [D]iagnostics' })
            vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]inder [R]esume' })
            vim.keymap.set('n', '<leader>f.', builtin.oldfiles, { desc = '[F]ind Recent Files' })
            vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = '[F]ind Existing [B]uffers' })
        end
    },

    {
        'nvim-telescope/telescope-ui-select.nvim',
        config = function()
            require("telescope").load_extension("ui-select")
        end
    }
}

