-- =============================================================================
-- vimwiki.lua · personal wiki / notes, markdown-flavored, kept out of your
-- main projects folder so `conform`'s markdown->prettier formatter and any
-- git repo it runs in doesn't touch it.
-- =============================================================================
return {
  "vimwiki/vimwiki",
  init = function()
    -- Must be set BEFORE the plugin loads — VimWiki reads these on load,
    -- not lazily, so this goes in `init`, not `config`.
    vim.g.vimwiki_list = {
      {
        path = "~/notes/wiki/",
        syntax = "markdown",
        ext = ".md",
      },
    }
    -- Don't hijack every *.md file on your system as a wiki page — only
    -- files actually inside the wiki path above count. Without this,
    -- opening any random README.md would try to activate wiki keymaps.
    vim.g.vimwiki_global = 0
  end,
  ft = { "vimwiki", "markdown" },
  keys = {
    { "<leader>ww",         "<cmd>VimwikiIndex<CR>",         desc = "[W]iki [W]iki index" },
    { "<leader>wt",         "<cmd>VimwikiTabIndex<CR>",      desc = "[W]iki index in [T]ab" },
    { "<leader>ws",         "<cmd>VimwikiUISelect<CR>",      desc = "[W]iki [S]elect" },
    { "<leader>wi",         "<cmd>VimwikiDiaryIndex<CR>",    desc = "[W]iki d[I]ary" },
    { "<leader>w<leader>w", "<cmd>VimwikiMakeDiaryNote<CR>", desc = "[W]iki new diary note" },
  },
}
