return {
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.6',
        dependencies = {
            'nvim-lua/plenary.nvim'
        },
        config = function()
            local builtin = require('telescope.builtin')
            local home_dir = vim.fn.getenv("HOME") -- typically /root in WSL

            -- 🔍 Local File Search (includes dotfiles)
            vim.keymap.set('n', '<leader>ff', function()
                builtin.find_files({
                    hidden = true
                })
            end, { desc = "[F]ind [F]iles (local + dotfiles)" })

            -- 🔍 Local Grep (word search)
            vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "[F]ind by [G]rep (local)" })

            -- 🔍 Global File Search from /root (includes dotfiles)
            vim.keymap.set('n', '<leader>gf', function()
                builtin.find_files({
                    cwd = home_dir,
                    hidden = true,
                    prompt_title = "Global File Search (/root)"
                })
            end, { desc = "[G]lobal [F]ile search (with dotfiles)" })

            -- 🔍 Global Grep from /root
            vim.keymap.set('n', '<leader>ggf', function()
                builtin.live_grep({
                    cwd = home_dir,
                    prompt_title = "Global Grep Search (/root)"
                })
            end, { desc = "[G]lobal [G]rep [F]ind" })

            -- 🔧 Other Useful Searches
            vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = '[F]ind [D]iagnostics' })
            vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]inder [R]esume' })
            vim.keymap.set('n', '<leader>f.', builtin.oldfiles, { desc = '[F]ind Recent Files' })
            vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = '[F]ind Existing [B]uffers' })
        end
    },
    {
        'nvim-telescope/telescope-ui-select.nvim',
        config = function()
            local actions = require("telescope.actions")

            require("telescope").setup({
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({})
                    }
                },
                defaults = {
                    mappings = {
                        i = {
                            ["<C-n>"] = actions.cycle_history_next,
                            ["<C-p>"] = actions.cycle_history_prev,
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                        }
                    }
                }
            })

            require("telescope").load_extension("ui-select")
        end
    }
}

