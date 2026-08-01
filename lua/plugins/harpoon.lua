return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },

  config = function()
    local harpoon = require("harpoon")

    -- REQUIRED
    harpoon:setup({
      settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
      },
    })

    -- 🔖 Mark current file
    vim.keymap.set("n", "<S-m>", function()
      harpoon:list():add()
    end, { desc = "Harpoon Mark File" })

    -- 📁 Toggle Harpoon menu
    vim.keymap.set("n", "<leader>th", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "Harpoon Toggle Menu" })

    -- 🔢 Jump to files 1-9
    for i = 1, 9 do
      vim.keymap.set("n", "<A-" .. i .. ">", function()
        harpoon:list():select(i)
      end, { desc = "Harpoon File " .. i })
    end

    -- 🔟 Jump to file 10
    vim.keymap.set("n", "<A-0>", function()
      harpoon:list():select(10)
    end, { desc = "Harpoon File 10" })

    -- ⏭ Next file
    vim.keymap.set("n", "<leader>hn", function()
      harpoon:list():next()
    end, { desc = "Harpoon Next" })

    -- ⏮ Previous file
    vim.keymap.set("n", "<leader>hp", function()
      harpoon:list():prev()
    end, { desc = "Harpoon Previous" })
  end,
}
