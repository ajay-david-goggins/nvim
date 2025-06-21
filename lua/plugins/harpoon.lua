return {
  "ThePrimeagen/harpoon",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim"
  },
  config = function()
    local mark = require("harpoon.mark")
    local ui = require("harpoon.ui")

    -- 🔖 Mark file with <Shift>m
    vim.keymap.set("n", "<S-m>", function()
      mark.add_file()
    end, { desc = "Harpoon Mark File" })

    -- 📁 Toggle Harpoon menu with <Tab>
    vim.keymap.set("n", "<Tab>", function()
      ui.toggle_quick_menu()
    end, { desc = "Harpoon Toggle Menu" })

    -- 🔢 Jump to files 1–9 using <Alt+1> to <Alt+9>
    for i = 1, 9 do
      vim.keymap.set("n", "<A-" .. i .. ">", function()
        ui.nav_file(i)
      end, { desc = "Harpoon: Go to file " .. i })
    end

    -- 🔟 Jump to file 10 using <Alt+0>
    vim.keymap.set("n", "<A-0>", function()
      ui.nav_file(10)
    end, { desc = "Harpoon: Go to file 10" })
  end,
}

