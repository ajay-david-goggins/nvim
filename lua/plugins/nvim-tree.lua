return {
  "nvim-tree/nvim-tree.lua",
  config = function()
    vim.keymap.set('n', '<leader>e', "<cmd>NvimTreeToggle<CR>", { desc = "Toggle [E]xplorer" })

    require("nvim-tree").setup({
      view = {
        width = 50,
        side = "left",
        number = true,
        relativenumber = true,
      },
      renderer = {
        indent_markers = {
          enable = true, -- 👈 this shows the connector lines
        },
      },
      hijack_netrw = true,
      auto_reload_on_write = true,
    })

    -- ✅ Auto color setup when NvimTree is opened
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "NvimTree",
      callback = function()
        -- 🔵 Line number colors
        vim.cmd("highlight NvimTreeLineNr guifg=#FFFFFF guibg=NONE")        -- White normal number
        vim.cmd("highlight NvimTreeCursorLineNr guifg=#87CEEB guibg=NONE")  -- Sky blue for current line number
        vim.cmd("highlight NvimTreeCursorLine guibg=#2C2C2C")               -- Optional: dark bg for current line

        -- ⚪ Connector color (│ ├─ └─ lines)
        vim.cmd("highlight NvimTreeIndentMarker guifg=#FFFFFF")             -- Make connector lines white
      end,
    })
  end,
}

