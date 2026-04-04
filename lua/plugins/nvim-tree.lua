return {
    "nvim-tree/nvim-tree.lua",
    config = function () 
        vim.keymap.set("n", "<leader>e", "<CMD>NvimTreeToggle<CR>", { desc = "Toggle [E]xplorer" } )
        require("nvim-tree").setup({
            hijack_netrw = true,  -- hijack the netrw and show instead  the nvim-tree
            auto_reload_on_write = true,
        })
    end
}
