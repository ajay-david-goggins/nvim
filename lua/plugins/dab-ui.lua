-- =============================================================================
-- dap-ui.lua · Neovim 0.13+
-- DAP UI sidebar + virtual text + full keymap set for debugging
-- =============================================================================

return {
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
        config = function()
            local dapui = require("dapui")
            local dap   = require("dap")

            dapui.setup()

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

            -- ── Keymaps ──────────────────────────────────────────────────────
            local map = function(mode, lhs, rhs, desc)
                vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
            end

            -- UI toggle
            map("n", "<leader>du", dapui.toggle,                         "  DAP Toggle UI")

            -- Hover / inspect value under cursor (no need to open REPL)
            map("n", "<leader>dh", function() dapui.eval(nil, { enter = true }) end, "  DAP Hover/Eval Under Cursor")
            map("v", "<leader>dh", function() dapui.eval(nil, { enter = true }) end, "  DAP Eval Selection")

            -- Floating scopes/frames windows (quick look without leaving the sidebar layout)
            map("n", "<leader>df", function() dapui.float_element("scopes", { enter = true }) end, "  DAP Float Scopes")
            map("n", "<leader>dF", function() dapui.float_element("stacks", { enter = true }) end, "  DAP Float Call Stack")

            -- Watches — add an expression to watch continuously
            map("n", "<leader>dw", function()
                local expr = vim.fn.input("Watch expression: ")
                if expr ~= "" then
                    require("dap.ui.widgets").hover(expr)
                end
            end, "  DAP Add Watch Expression")

            -- Breakpoints list (all breakpoints across the whole project, not just current file)
            map("n", "<leader>dB", function() dapui.float_element("breakpoints", { enter = true }) end, "  DAP Float Breakpoints List")

            -- Conditional breakpoint (only stops when the expression is true — e.g. usr == "someone@x.com")
            map("n", "<leader>dC", function()
                local cond = vim.fn.input("Breakpoint condition: ")
                require("dap").set_breakpoint(cond)
            end, "  DAP Conditional Breakpoint")

            -- Log point (prints a message at that line without stopping — like console.log but via DAP)
            map("n", "<leader>dL", function()
                local msg = vim.fn.input("Log message: ")
                require("dap").set_breakpoint(nil, nil, msg)
            end, "  DAP Log Point")

            -- Clear all breakpoints in the project
            map("n", "<leader>dX", function() require("dap").clear_breakpoints() end, "  DAP Clear All Breakpoints")

            -- Restart the current debug session without reselecting the config
            map("n", "<leader>dR", function() require("dap").restart() end, "  DAP Restart Session")

            -- Terminate cleanly (frees the port, kills the session)
            map("n", "<leader>dq", function() require("dap").terminate() end, "  DAP Terminate Session")

            -- Run to cursor — continue execution until it hits the current line
            map("n", "<leader>dv", function() require("dap").run_to_cursor() end, "  DAP Run To Cursor")

            -- Step back / reverse step (only works if the adapter supports it — debugpy does not by default,
            -- kept here in case you enable it later; harmless no-op otherwise)
            map("n", "<lea--[[ d ]]er>dk", function() require("dap").step_back() end, "  DAP Step Back")
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

-- <leader>db	Toggle breakpoint 
-- <leader>dc	Continue 
-- <leader>di	Step Into 
-- <leader>do	Step Over 
-- <leader>dO	Step Out 
-- <leader>dr	Open REPL 
-- <leader>dl	Run Last 
-- <leader>du	Toggle DAP UI sidebar
-- <leader>dh	Hover/eval value under cursor (normal + visual)
-- <leader>df	Float Scopes window
-- <leader>dF	Float Call Stack window
-- <leader>dw	Add watch expression
-- <leader>dB	Float Breakpoints list (whole project)
-- <leader>dC	Set conditional breakpoint
-- <leader>dL	Set log point (print without stopping)
-- <leader>dX	Clear all breakpoints
-- <leader>dR	Restart session
-- <leader>dq	Terminate session
-- <leader>dv	Run to cursor
-- <leader>dk	Step back (debugpy support limited)
