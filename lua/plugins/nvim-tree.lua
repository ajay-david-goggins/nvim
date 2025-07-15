return {
    "nvim-tree/nvim-tree.lua",
    config = function()
        vim.keymap.set('n', '<leader>e', "<cmd>NvimTreeToggle<CR>", {desc = "Toggle [E]xplorer"})

        require("nvim-tree").setup({
            view = {
                width = 50,
                side = "left",
                number = true,
                relativenumber = true,
            },
            hijack_netrw = true,
            auto_reload_on_write = true,
        })

        -- 🔵 Current line number in SkyBlue
        vim.api.nvim_set_hl(0, "NvimTreeCursorLineNr", { fg = "#87ceeb", bold = true })  -- SkyBlue

        -- ⚪ All other numbers in White
        vim.api.nvim_set_hl(0, "NvimTreeLineNr", { fg = "#ffffff" })

        -- Optional: Highlight full line under cursor
        vim.cmd [[
            autocmd FileType NvimTree setlocal cursorline
        ]]
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2a2a2a" }) -- Customize if needed
    end
}

