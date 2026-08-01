return {
    "Mofiqul/dracula.nvim",
    lazy = false,
    priority  = 1000, -- load this plugin first before default
    config = function ()
        vim.cmd.colorscheme  "dracula"
    end
}
