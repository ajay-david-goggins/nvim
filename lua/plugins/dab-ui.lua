return {
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
        config = function()
            local dapui = require("dapui")
            dapui.setup()

            local dap = require("dap")
            -- Auto open/close the UI with the debug session
            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end

            vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "  DAP Toggle UI" })
        end,
    },
    {
        "theHamsta/nvim-dap-virtual-text",
        dependencies = { "mfussenegger/nvim-dap" },
        opts = {
            enabled = true,
            commented = false,
            virt_text_pos = "eol",
        },
    },
}
