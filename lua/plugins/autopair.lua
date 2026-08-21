-- Bracket-insert-on-completion-confirm is now handled by blink.cmp itself
-- (completion.accept.auto_brackets in plugins/completion.lua), so this no
-- longer depends on nvim-cmp at all.
return {
    "windwp/nvim-autopairs",
    -- Load on InsertEnter to keep startup time near zero
    event = "InsertEnter",
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
    end,
}
