return {
    "nvim-tree/nvim-tree.lua",
    config = function()
        -- Keymap to toggle the explorer
        vim.keymap.set("n", "<leader>e", "<CMD>NvimTreeToggle<CR>", { desc = "Toggle [E]xplorer" })

        require("nvim-tree").setup({
            -- 1. THIS SECTIONS FIXES THE SYNCING ISSUE
            update_focused_file = {
                enable = true,
                update_root = false, -- Set to true if you want the root to change to the file's directory
                ignore_list = {},
            },
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
