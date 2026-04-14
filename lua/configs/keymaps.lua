local K = vim.keymap.set
vim.g.leader = " "
vim.g.mapleader = " "

K("n", "<Esc>", "<CMD>nohlsearch<CR>", { desc = "Remove search highlights" })
K("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

K("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
K("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
K("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
K("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

K("n", "<leader>wv", "<CMD>vsplit<CR>", { desc = "[W]indow Split [V]ertically" })
K("n", "<leader>wh", "<CMD>split<CR>", { desc = "[W]indow Split [H]orizontally" })

-- Moving Line  [ N + V ]
K("n", "<A-j>", "<CMD>m .+1<CR>==", { desc = "Move one line down" })
K("n", "<A-k>", "<CMD>m .-2<CR>==", { desc = "Move one line up" })

K("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move one line down" })

K("n", "<A-l>", ">>", { desc = "Indent right" })
K("n", "<A-h>", "<<", { desc = "Indent right" })
K("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move one line up" })

K("v", "<A-l>", ">gv", { desc = "Indent right" })
K("v", "<A-h>", "<gv", { desc = "Indent left" })

-- diagnostic
K("n", "<leader>cm", vim.diagnostic.open_float, { desc = "[C]ode [M]essage" })

-- genenral
K("n", "<leader>q", "<CMD>q<CR>", { desc = "[Q]uit for single file" })
K("n", "<leader>qa", "<CMD>qa<CR>", { desc = "[Q]uit [A]ll files" })

K("n", "<A-L>", ":vertical resize +2<CR>", { desc = "Make window left" })
K("n", "<A-J>", ":resize +2<CR>", { desc = "Make window down" })
K("n", "<A-K>", ":resize -2<CR>", { desc = "Make window up" })
K("n", "<A-H>", ":vertical resize -2<CR>", { desc = "Make window right" })

K("n", "<leader>tt", ":belowright split | resize 10 | terminal<CR>", { desc = "[T]iny [T]erminal", silent = true })

-- wrap text
K("n", "<A-z>", function()
    vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle word wrap for current file", silent = true }) -- local file

K("n", "<A-Z>", function()
    vim.opt.wrap = not vim.opt.wrap:get()
end, { desc = "Toggle word wrap for every file", silent = true }) -- every file


K("n", "<leader>a", "ggVG", { desc = "Make window narrower" })

-- auto save
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
    pattern = "*",
    callback = function()
        if vim.bo.modified and vim.bo.modifiable then
            vim.cmd("silent! write")
        end
    end,
})

-- Manual Formatting Keymap
vim.keymap.set("n", "<leader>fwc", function()
    vim.lsp.buf.format({ async = true })
    print("Prettier: Whole File Code Formatted! ✨")
end, { desc = "[F]ormat [W]hole [C]ode with Prettier/LSP" })

-- Format ONLY the selection (Visual Mode)
vim.keymap.set("v", "<leader>fsc", function()
    vim.lsp.buf.format({
        async = true,
        range = {
            ["start"] = vim.api.nvim_buf_get_mark(0, "<"),
            ["end"] = vim.api.nvim_buf_get_mark(0, ">"),
        }
    })
    print("Prettier: Formatted selected code! 🎯")
end, { desc = "[F]ormat [S]eleced [C]ode only" })
