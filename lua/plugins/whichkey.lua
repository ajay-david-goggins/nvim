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
            { "<leader>p", group = "[P]ostman / API Client" },
            { "<leader>pr", desc = "  [P]ostman [R]un request (Telescope)" },
            { "<leader>pc", desc = "  [P]ostman select [C]ollection" },
            { "<leader>pe", desc = "  [P]ostman select [E]nvironment" },
            { "<leader>pE", desc = "  [P]ostman [E]dit environment JSON (split)" },
            { "<leader>pm", desc = "  [P]ostman [M]odify variable interactively" },
            { "<leader>pw", desc = "  [P]ostman [W]orkspace / Studio (edit payload)" },
            { "<leader>ph", desc = "  [P]ostman [H]istory browser" },
            { "<leader>pv", desc = "  [P]ostman [V]iew last response" },
            { "<leader>px", desc = "  [P]ostman e[X]tract var from response" },
            { "<leader>p?", desc = "  [P]ostman show active variables" },
            { "<leader>s", group = "[S]earch (project root)" },
            { "<leader>t", group = "[T]oggle" },
            { "<leader>w", group = "[W]indow / [W]iki" },
            { "<leader>wg", group = "[W]iki [G]it" },
            -- { "<leader>J", group = "[J]ava" },
        })
    end,
}
