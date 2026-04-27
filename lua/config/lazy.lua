-- =============================================================================
-- lazy.lua  ·  Bootstrap for lazy.nvim  ·  Mobile-optimized
-- =============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = {
        { import = "plugins" },
    },
    defaults    = { lazy = true },           -- everything lazy by default
    change_detection = { notify = false },   -- no noise on config changes
    performance = {
        rtp = {
            disabled_plugins = {             -- strip unused built-ins
                "gzip", "matchit", "matchparen",
                 "tarPlugin", "tohtml",
                    "tutor", "zipPlugin",
                },
        },
    },
})
