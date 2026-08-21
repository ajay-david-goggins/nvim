return {
    "folke/which-key.nvim",
    event = "VimEnter",
    config = function()
        local wk = require("which-key")
        wk.setup({
            -- You can leave this empty for defaults, 
            -- or customize the UI here
            preset = "modern", -- Clean look for Neovim 0.13
        })

        -- The new v3 way to register prefixes
        wk.add({
            { "<leader>/", group = "Comments" },
            { "<leader>c", group = "[C]ode" },
            { "<leader>d", group = "[D]iagnostics / DAP" },
            { "<leader>ds", group = "[D]ap [S]tep" },
            { "<leader>e", group = "[E]xplorer" },
            { "<leader>f", group = "[F]ind (local)" },
            { "<leader>g", group = "[G]it" },
            { "<leader>s", group = "[S]earch (project root)" },
            { "<leader>t", group = "[T]oggle" },
            { "<leader>w", group = "[W]indow" },
            -- { "<leader>J", group = "[J]ava" },
        })
    end,
}
