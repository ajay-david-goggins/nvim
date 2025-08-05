return {
  "nvim-tree/nvim-tree.lua",
  config = function()
    local nvimtree = require("nvim-tree")

    -- ≡ƒî¿ Keymaps
    vim.keymap.set('n', '<leader>e', "<cmd>NvimTreeToggle<CR>", { desc = "Toggle [E]xplorer" })

    vim.keymap.set('n', '<leader>eo', function()
      vim.cmd("NvimTreeOpen")
      vim.cmd("NvimTreeResize 50")
      vim.cmd("NvimTreeRefresh")
    end, { desc = "Open Tree & Resize safely" })

    vim.keymap.set('n', '<leader>er', "<cmd>NvimTreeFindFile<CR>", { desc = "Refocus on current file" })

    -- ≡ƒÜÖ NvimTree Setup
    nvimtree.setup({
      view = {
        width = 50,
        side = "left",
        number = true,
        relativenumber = true,
      },
      renderer = {
        indent_markers = {
          enable = true, -- tree branch lines
        },
      },
      hijack_netrw = true,
      auto_reload_on_write = true,
      update_focused_file = {
        enable = true,
        update_root = false,
        ignore_list = {},
      },
      filters = {
        dotfiles = false,
      },
      actions = {
        open_file = {
          resize_window = true,
        },
      },
    })

    -- ≡ƒÄ¿ Tree-specific highlight setup
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "NvimTree",
      callback = function()
        vim.cmd("highlight NvimTreeLineNr guifg=#FFFFFF guibg=NONE")
        vim.cmd("highlight NvimTreeCursorLineNr guifg=#87CEEB guibg=NONE")
        vim.cmd("highlight NvimTreeCursorLine guibg=#2C2C2C")
        vim.cmd("highlight NvimTreeIndentMarker guifg=#FFFFFF")
      end,
    })
  end,
}

