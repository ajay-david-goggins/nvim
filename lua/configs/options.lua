vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.numberwidth = 4
vim.opt.wrap = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false

vim.opt.expandtab = true
vim.opt.shiftwidth = 2 -- convert the >> or << with number of space
vim.opt.tabstop = 2 -- number of space character inserted for /t 
vim.opt.softtabstop = 2 -- number of space character insteader for <Tab> key
vim.opt.smartindent = true -- enable smart indentation
vim.opt.breakindent = true

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.mouse="a"
vim.opt.conceallevel = 3
vim.opt.clipboard = "unnamedplus"
vim.opt.fileencoding = "utf-8"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.termguicolors = true
vim.opt.showmode = true
vim.opt.cursorline = true
vim.opt.cursorcolumn = true

-- Fucking execution Timing 
vim.opt.timeoutlen = 300 -- for keymap execution time out limit in 0.3 sec 
vim.opt.updatetime = 250 -- this is responsible for showing error like git or backup file does
vim.opt.ttimeoutlen = 10 -- this is terminal time out lenth execute <Esc> <Tab> immediately 

vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.cmd [[
    highlight LineNr guifg=#ffffff
    highlight LineNrAbove guifg=#ffffff
    highlight LineNrBelow guifg=#ffffff
    highlight CursorLineNr guifg=#00BFFF gui=bold
]]

-- This makes brackets inside Tailwind classes look like normal text
vim.api.nvim_set_hl(0, "@punctuation.bracket.javascript", { link = "String" })

-- TESTING DIFFERENT GREENS --

-- Option 1: Classic Grass Green (Bright & Readable)
vim.api.nvim_set_hl(0, "Comment", { fg = "#7cfc00", italic = true })

-- Option 2: Yellow-Green (Neon style, very high contrast)
-- vim.api.nvim_set_hl(0, "Comment", { fg = "#adff2f", italic = true })

-- Option 3: Forest Green (Darker, easier on the eyes for long sessions)
-- vim.api.nvim_set_hl(0, "Comment", { fg = "#228b22" })

-- Option 4: Seafoam Green (Clean, modern look)
-- vim.api.nvim_set_hl(0, "Comment", { fg = "#3cb371", bold = true })
