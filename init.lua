-- =============================================================================
-- init.lua  ·  Neovim entry point
-- =============================================================================
require("config.options")    -- basic vim options
require("config.keymaps")    -- global keymaps (non-LSP)
require("config.lazy")       -- plugin loader
