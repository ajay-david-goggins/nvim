return {
    "nvim-tree/nvim-tree.lua",
    config = function()
        -- Keymap to toggle the explorer and find/focus current file
        vim.keymap.set("n", "<leader>e", function()
            require("nvim-tree.api").tree.toggle({ find_file = true, focus = true, update_root = true })
        end, { desc = "Toggle [E]xplorer (find current file)" })

        require("nvim-tree").setup({
            -- Auto-sync tree to current file on any buffer switch / jump to definition
            update_focused_file = {
                enable = true,
                update_root = {
                    enable = true,
                    ignore_list = {},
                },
                exclude = false,
            },
            -- Ensure no files or packages (node_modules, .venv, dotfiles, etc.) are hidden from tree sync
            filters = {
                dotfiles = false,
                git_ignored = false,
            },
            sync_root_with_cwd = true,
            view = {
                width = 50,
                side = "left",
                number = true,
                relativenumber = true,
            },
            renderer = {
                indent_markers = {
                    enable = true,
                },
            },
            hijack_netrw = true,
            auto_reload_on_write = true,

            -- 2. CUSTOM KEYMAPS INSIDE THE TREE
            on_attach = function(bufnr)
                local api = require('nvim-tree.api')

                local function opts(desc)
                    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
                end

                -- Default mappings
                api.config.mappings.default_on_attach(bufnr)

                -- 3. THE "EXPAND/COLLAPSE ALL" TOGGLE (Mapped to 'C')
                -- You can change "C" to whatever key you like
                vim.keymap.set('n', 'C', function()
                    -- local node = api.tree.get_node_under_cursor()
                    -- If the tree is mostly collapsed, expand all. Otherwise collapse.
                    api.tree.expand_all()
                    -- Note: nvim-tree doesn't have a perfect "toggle_all", 
                    -- but 'api.tree.collapse_all()' is the counterpart.
                end, opts('Expand All'))
                vim.keymap.set('n', 'W', api.tree.collapse_all, opts('Collapse All'))
            end,
        })

        -- Your existing Autocmds for styling
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "NvimTree",
            callback = function()
                vim.cmd("highlight NvimTreeLineNr guifg=#FFFFFF guibg=NONE")
                vim.cmd("highlight NvimTreeCursorLineNr guifg=#87CEEB guibg=NONE")
                vim.cmd("highlight NvimTreeCursorLine guibg=#2C2C2C")
                vim.cmd("highlight NvimTreeIndentMarker guifg=#FFFFFF")
            end
        })
    end
}
