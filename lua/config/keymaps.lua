--Set our leader keybinding to space
-- Anywhere you see <leader> in a keymapping specifies the space key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Remove search highlights after searching
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Remove search highlights" })

-- Exit Vim's terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- OPTIONAL: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- Easily split windows
vim.keymap.set("n", "<leader>wv", ":vsplit<cr>", { desc = "[W]indow Split [V]ertical" })
vim.keymap.set("n", "<leader>wh", ":split<cr>", { desc = "[W]indow Split [H]orizontal" })

-- Stay in indent mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left in visual mode" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right in visual mode" })

-- 💾 Save in insert mode
vim.keymap.set("i", "<leader><leader>w", "<cmd>w<CR>", {
    desc = "Write the file (insert mode)",
    silent = true,
    noremap = true,
})

vim.keymap.set("n","<leader>cm", vim.diagnostic.open_float,{ desc = "[C]ode [M]essage" })
 
-- 💾 Save in normal mode
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", {
    desc = "Write the file",
    silent = true,
    noremap = true,
})

-- 💾 Save and quit
vim.keymap.set("n","<leader>wq", "<cmd>wq<CR>", {
    desc = "Write and quit",
    silent = true,
    noremap = true,
})

-- ❌ Quit
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", {
    desc = "Quit file",
    silent = true,
    noremap = true,
})


-- 💾 Save and quit all
vim.keymap.set("n", "<leader>wqa", "<cmd>wqa<CR>", {
    desc = "Write and quit all",
    silent = true,
    noremap = true,
})

vim.keymap.set("n", "<leader>cm", vim.diagnostic.open_float, {desc = "[C]ode [M]essage"})

-- 📋 Copy to Windows clipboard in visual mode
vim.keymap.set("v", "<leader>y", "<cmd>w !clip.exe<CR><CR>", {
    desc = "Copy selection to clipboard",
    silent = true,
    noremap = true,
})

-- 📥 Paste from Windows clipboard in normal mode
vim.keymap.set("n", "<leader>p", "<cmd>r !powershell.exe -command \"Get-Clipboard\"<CR>", {
    desc = "Paste from clipboard",
    silent = true,
    noremap = true,
})

vim.keymap.set("n", "<A-z>", function()
    vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle Word Wrap (Alt + z)", silent = true })

-- Resize splits using Alt + hjkl
vim.keymap.set("n", "<A-h>", ":vertical resize -2<CR>", { desc = "Resize split left", silent = true })
vim.keymap.set("n", "<A-l>", ":vertical resize +2<CR>", { desc = "Resize split right", silent = true })
vim.keymap.set("n", "<A-j>", ":resize +2<CR>", { desc = "Resize split down", silent = true })
vim.keymap.set("n", "<A-k>", ":resize -2<CR>", { desc = "Resize split up", silent = true })

vim.keymap.set("n", "<leader>tt", ":belowright split | resize 10 | terminal<CR>", { desc = "Tiny Terminal", silent = true })

vim.keymap.set("n", "<leader>ce", function()
    -- require("eslint").setup() // don't do this 
end, { desc = "Create ESLint config" })-- 💥 Force save and quit all
vim.keymap.set("n", "<leader>wqa!", "<cmd>wqa!<CR>", {
    desc = "Force write and quit all",
    silent = true,
    noremap = true,
})

-- ❌ Force quit all
vim.keymap.set("n", "<leader>qa!", "<cmd>qa!<CR>", {
    desc = "Force quit all",
    silent = true,
    noremap = true,
})



vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  pattern = "*",
  callback = function()
    if vim.bo.modified and vim.bo.modifiable then
      vim.cmd("silent! write")
    end
  end,
})

-- Like windows 10 ctrl + a 
vim.keymap.set("n", "<leader>a", "ggVG", { desc = "Select All" })
