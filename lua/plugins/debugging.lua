return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "mxsdev/nvim-dap-vscode-js",
        {
            "microsoft/vscode-js-debug",
            version = "1.x",
            build = "npm i && npm run compile vsDebugServerBundle && mv dist out"
        }
    },
    config = function()
        -- Import required modules
        local dap = require("dap")
        local dapui = require("dapui")

        -- Setup JavaScript/Typescript adapter
        require("dap-vscode-js").setup({
            debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug",
            adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
        })

        -- Define debug configurations for JavaScript and TypeScript
        for _, language in ipairs({ "javascript", "typescript" }) do
            dap.configurations[language] = {
                {
                    type = "pwa-node",
                    request = "launch",
                    name = "Launch file",
                    program = "${file}",
                    cwd = "${workspaceFolder}",
                },
                {
                    type = "pwa-node",
                    request = "attach",
                    name = "Attach",
                    processId = require("dap.utils").pick_process,
                    cwd = "${workspaceFolder}",
                },
                {
                    type = "pwa-node",
                    request = "launch",
                    name = "Debug Jest Tests",
                    runtimeExecutable = "node",
                    runtimeArgs = {
                        "./node_modules/jest/bin/jest.js",
                        "--runInBand",
                    },
                    rootPath = "${workspaceFolder}",
                    cwd = "${workspaceFolder}",
                    console = "integratedTerminal",
                    internalConsoleOptions = "neverOpen",
                },
                {
                    type = "pwa-chrome",
                    request = "launch",
                    name = "Launch Chrome",
                    url = "http://localhost:3000",
                    webRoot = "${workspaceFolder}",
                    sourceMaps = true,
                },
            }
        end

        -- Initialize DAP UI
        dapui.setup()

        -- Setup DAP UI listeners to open/close UI automatically
        dap.listeners.before.attach.dapui_config = function() dapui.open() end
        dap.listeners.before.launch.dapui_config = function() dapui.open() end
        dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
        dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

        -- Keymaps for debugging
        vim.keymap.set("n", "<Leader>dc", function() require("dap").continue() end, { desc = "[D]ebugger [C]ontinue", silent = true })
        vim.keymap.set("n", "<Leader>dso", function() require("dap").step_over() end, { desc = "[D]ebugger [S]tep [O]ver", silent = true })
        vim.keymap.set("n", "<Leader>dsi", function() require("dap").step_into() end, { desc = "[D]ebugger [S]tep [I]nto", silent = true })
        vim.keymap.set("n", "<Leader>dsO", function() require("dap").step_out() end, { desc = "[D]ebugger [S]tep [^O]ut", silent = true })
        vim.keymap.set("n", "<Leader>dtb", function() require("dap").toggle_breakpoint() end, { desc = "[D]ebugger [T]oggle [B]reakpoint", silent = true })
        vim.keymap.set("n", "<Leader>dsb", function() require("dap").set_breakpoint() end, { desc = "[D]ebugger [S]et [B]reakpoint", silent = true })
        vim.keymap.set("n", "<Leader>dlp", function() require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: ")) end, { desc = "[D]ebugger Set Enpoint [L]og [P]oint", silent = true })
        vim.keymap.set("n", "<Leader>dr", function() require("dap").repl.open() end, { desc = "[D]ebugger [R]eplace", silent = true })
        vim.keymap.set("n", "<Leader>drl", function() require("dap").run_last() end, { desc = "[D]ebugger [R]un [L]ast", silent = true })
        vim.keymap.set({"n", "v"}, "<Leader>dh", function() require("dap.ui.widgets").hover() end, { desc = "[D]ebugger [H]over", silent = true })
        vim.keymap.set({"n", "v"}, "<Leader>dp", function() require("dap.ui.widgets").preview() end, { desc = "[D]ebugger [P]review", silent = true })
        vim.keymap.set("n", "<Leader>df", function()
            local widgets = require("dap.ui.widgets")
            widgets.centered_float(widgets.frames)
        end, { desc = "[D]ebugger [F]rame", silent = true })
        vim.keymap.set("n", "<Leader>ds", function()
            local widgets = require("dap.ui.widgets")
            widgets.centered_float(widgets.scopes)
        end, { desc = "[D]ebugger [S]copes", silent = true })

        -- Debug print to verify config
        print("DAP configurations loaded for JavaScript/TypeScript")
    end,
}
