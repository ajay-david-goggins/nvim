return {
    "windwp/nvim-autopairs",
    -- Load on InsertEnter to keep startup time near zero
    event = "InsertEnter",
    dependencies = { "hrsh7th/nvim-cmp" },
    config = function()
        local autopairs = require("nvim-autopairs")

        autopairs.setup({
            check_ts = true, -- Use Treesitter to check for context
            ts_config = {
                lua = { "string", "source" }, -- Don't add pairs in lua strings
                javascript = { "template_string" },
                java = false,
            },
            -- Fast Wrap: Press Alt+e (<M-e>) to wrap a word in brackets
            fast_wrap = {
                map = "<M-e>",
                chars = { "{", "[", "(", '"', "'" },
                pattern = [=[[%'%"%)%>%]%]%}%, ]]=],
                offset = 0,
                end_key = "$",
                keys = "qwertyuiopzxcvbnmasdfghjkl",
                check_comma = true,
                highlight = "PmenuSel",
                highlight_grey = "LineNr",
            },
        })
        pcall(function()
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            local cmp = require("cmp")
            cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end)
    end,
}
