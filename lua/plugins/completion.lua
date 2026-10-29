-- Replaces nvim-cmp + 6 cmp-* dependencies + LuaSnip glue (~150 lines before)
-- with one Rust-backed engine. Uses "super-tab" keymap preset for <Tab>
-- completion and navigation.
return {
  "saghen/blink.cmp",
  event = "InsertEnter",
  version = "1.*",
  dependencies = {
    "rafamadriz/friendly-snippets",
    "kristijanhusak/vim-dadbod-completion",
  },
  opts = {
    keymap = { preset = "super-tab" },
    appearance = { nerd_font_variant = "mono" },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      menu = { border = "rounded" },
      list = { selection = { preselect = false, auto_insert = true } },
    },
    signature = { enabled = true, window = { border = "rounded" } },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
      per_filetype = {
        sql = { "snippets", "dadbod", "buffer" },
        mysql = { "snippets", "dadbod", "buffer" },
        plsql = { "snippets", "dadbod", "buffer" },
      },
      providers = {
        dadbod = {
          name = "Dadbod",
          module = "vim_dadbod_completion.blink",
          score_offset = 100,
        },
      },
    },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
