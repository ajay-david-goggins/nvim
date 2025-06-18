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
    end
}
