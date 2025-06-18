-- ~/.config/nvim/lua/snippets/php.lua
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node

return {
  s("php", {
    t({ "<?php", "", "?>" }),
  }),
}

