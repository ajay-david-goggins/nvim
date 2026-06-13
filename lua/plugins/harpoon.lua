return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",

  dependencies = {
    "nvim-lua/plenary.nvim",
  },

  config = function()
    local harpoon = require("harpoon")

    harpoon:setup()

    vim.keymap.set("n", "<S-m>", function()
      harpoon:list():add()
    end)

    vim.keymap.set("n", "<leader>th", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end)

    for i = 1, 9 do
      vim.keymap.set("n", "<A-" .. i .. ">", function()
        harpoon:list():select(i)
      end)
    end

    vim.keymap.set("n", "<A-0>", function()
      harpoon:list():select(10)
    end)
  end,
}
