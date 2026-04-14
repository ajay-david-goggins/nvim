print("hello From init file")

-- store the lazy repe in lazypath standard path 
local lazypath = vim.fn.stdpath("data").. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath
    })
end

vim.opt.rtp:prepend(lazypath)

local opts = {
    change_detection = {
        notify = false, -- config update change detection notification off 
    },
    checker  = {
        enabled = true, -- updates
        notify = false, -- disable notification
    },
}


require ("configs.options")
require ("configs.keymaps")

require ("lazy").setup ("plugins", opts)

print("bye from inti file")
