return {
    "nvim-tree/nvim-tree.lua",
    config = function ()
        vim.keymap.set("n", "<leader>e", "<CMD>NvimTreeToggle<CR>", { desc = "Toggle [E]xplorer" } )
        require("nvim-tree").setup({
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
            hijack_netrw = true,  -- hijack the netrw and show instead  the nvim-tree
            auto_reload_on_write = true,
        })

        vim.api.nvim_create_autocmd("FileType", {
            pattern = "NvimTree",
            callback = function ()
                vim.cmd("highlight NvimTreeLineNr guifg=#FFFFFF guibg=NONE") -- white normal numbers
                vim.cmd("highlight NvimTreeCursorLineNr guifg=#87CEEB guibg=NONE") -- Skyblue for Current number
                vim.cmd("highlight NvimTreeCursorLine guibg=#2C2C2C") -- white normal numbers
                -- ⚪ Connector color (│ ├─ └─ lines)
                vim.cmd("highlight NvimTreeIndentMarker guifg=#FFFFFF")
            end
        })
    end
}
