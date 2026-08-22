-- =============================================================================
-- plugins/hlslens.lua · nvim-hlslens
--
-- Bonus, belt-and-suspenders fix for the search-match-count regression: this
-- renders "[3/12]" as virtual text right next to the current match, driven
-- entirely by its own autocmds -- it does NOT depend on 'laststatus' at all,
-- so it keeps working even if globalstatus ever gets turned back on in
-- plugins/statusline.lua. The native indicator (now restored by disabling
-- globalstatus there) still works too; this just makes it impossible for a
-- future statusline tweak to silently take it away again.
-- =============================================================================
return {
  "kevinhwang91/nvim-hlslens",
  event = "VeryLazy",
  config = function()
    require("hlslens").setup({
      calm_down = true, -- clear the lens once you move off the search
    })

    local map = vim.keymap.set
    local opts = { noremap = true, silent = true }

    map("n", "n", [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], opts)
    map("n", "N", [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], opts)
    map("n", "*", [[*<Cmd>lua require('hlslens').start()<CR>]], opts)
    map("n", "#", [[#<Cmd>lua require('hlslens').start()<CR>]], opts)
    map("n", "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], opts)
    map("n", "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], opts)
  end,
}
