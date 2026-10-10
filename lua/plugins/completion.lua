-- Replaces nvim-cmp + 6 cmp-* dependencies + LuaSnip glue (~150 lines before)
-- with one Rust-backed engine. Same <Tab>/<C-n>/<C-p> muscle memory via the
-- "default" keymap preset.
return {
  "saghen/blink.cmp",
  event = "InsertEnter",
  version = "1.*",
  dependencies = { "rafamadriz/friendly-snippets" },
  opts = {
    keymap = { preset = "default" }, -- <C-y> accept, <C-n>/<C-p> select, <C-space> open docs
    appearance = { nerd_font_variant = "mono" },
    completion = {
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 250,
        window = { border = "rounded", max_height = 10, max_width = 50 },
      },
      menu = {
        border = "rounded",
        max_height = 8,
      },
      list = { selection = { preselect = false } },
    },
    signature = { enabled = true, window = { border = "rounded", max_height = 6 } },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
