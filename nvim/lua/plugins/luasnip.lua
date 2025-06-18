-- ~/.config/nvim/lua/plugins/luasnip.lua

return {
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets", -- Optional: for extra VSCode-style snippets
    },
    config = function()
      local luasnip = require("luasnip")

      -- Load friendly snippets (optional, includes common HTML, JS, PHP, etc.)
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Load your custom Lua snippets
      require("luasnip.loaders.from_lua").lazy_load({
        paths = { "~/.config/nvim/lua/snippets" },
      })

      -- Optional: Enable snippet history and update events
      luasnip.config.set_config({
        history = true,
        updateevents = "TextChanged,TextChangedI",
      })
    end,
  }
}

