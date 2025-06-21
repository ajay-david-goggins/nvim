return {
  -- example snippet plugin config (if you use LuaSnip)
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets"
    },
    config = function()
      require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/lua/snippets" })
    end,
  },
}

