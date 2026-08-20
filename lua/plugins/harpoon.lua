return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",

  event = "VeryLazy",

  dependencies = {
    "nvim-lua/plenary.nvim",
  },

  config = function()
    local harpoon = require("harpoon")

    -- =========================================================================
    -- HARPOON SETUP
    -- =========================================================================
    harpoon:setup({
      settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
      },
    })

    -- =========================================================================
    -- MARK CURRENT FILE
    -- =========================================================================
    vim.keymap.set("n", "<S-m>", function()
      harpoon:list():add()
    end, {
      desc = "Harpoon Mark File",
    })

    -- =========================================================================
    -- TOGGLE HARPOON MENU
    -- =========================================================================
    vim.keymap.set("n", "<leader>th", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, {
      desc = "Harpoon Toggle Menu",
    })

    -- =========================================================================
    -- JUMP TO FILES 1-9
    -- =========================================================================
    for i = 1, 9 do
      vim.keymap.set("n", "<A-" .. i .. ">", function()
        harpoon:list():select(i)
      end, {
        desc = "Harpoon File " .. i,
      })
    end

    -- =========================================================================
    -- JUMP TO FILE 10
    -- =========================================================================
    vim.keymap.set("n", "<A-0>", function()
      harpoon:list():select(10)
    end, {
      desc = "Harpoon File 10",
    })

    -- =========================================================================
    -- NEXT FILE
    -- =========================================================================
    vim.keymap.set("n", "<leader>hn", function()
      harpoon:list():next()
    end, {
      desc = "Harpoon Next",
    })

    -- =========================================================================
    -- PREVIOUS FILE
    -- =========================================================================
    vim.keymap.set("n", "<leader>hp", function()
      harpoon:list():prev()
    end, {
      desc = "Harpoon Previous",
    })
  end,
}
