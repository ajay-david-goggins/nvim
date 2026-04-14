return {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
        -- 1. Setup the context string plugin first (modern requirement)
        require('ts_context_commentstring').setup {
            enable_autocmd = false,
        }

        local comment = require("Comment")
        local ts_context_comment_string = require("ts_context_commentstring.integrations.comment_nvim")

        -- 2. Setup Comment.nvim
        comment.setup({
            -- This hook is what allows you to comment JSX/TSX correctly
            pre_hook = ts_context_comment_string.create_pre_hook(),
        })

        -- 3. Corrected Keymaps
        local api = require("Comment.api")

        -- Toggle current line (Normal Mode)
        vim.keymap.set("n", "<leader>/", api.toggle.linewise.current, { desc = "Comment Line" })

        -- Toggle selection (Visual Mode) - THIS WAS THE MAIN FIX
        vim.keymap.set("v", "<leader>/", "<ESC><CMD>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", { desc = "Comment Selected" })
    end,
}
