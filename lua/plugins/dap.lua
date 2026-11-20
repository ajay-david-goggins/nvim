return {
  "mfussenegger/nvim-dap",
  lazy = true,

  -- Unified DAP core keymaps — identical letters across every language
  -- (Python, Go, Java...). Defined ONCE here instead of duplicated in
  -- each lang/*.lua. Zero letter overlap with Diagnostics (configs/lsp.lua)
  -- or with dap-ui's extras (plugins/dab-ui.lua). Test runners (dt/dT)
  -- stay per-language since "test" has no universal DAP equivalent.
  keys = {
    { "<leader>db",  function() require("dap").toggle_breakpoint() end, desc = "  [D]ap [B]reakpoint toggle" },
    {
      "<leader>dc",
      function()
        if vim.bo.modified and vim.bo.buftype == "" then
          vim.cmd("silent! write")
        end
        require("dap").continue({ new = true })
      end,
      desc = "  [D]ap [C]ontinue / Start",
    },
    { "<leader>dso", function() require("dap").step_over() end,         desc = "  [D]ap [S]tep [O]ver" },
    { "<leader>dsi", function() require("dap").step_into() end,         desc = "  [D]ap [S]tep [I]nto" },
    { "<leader>dsO", function() require("dap").step_out() end,          desc = "  [D]ap [S]tep [O]ut" },
    { "<leader>dr",  function() require("dap").repl.open() end,         desc = "  [D]ap [R]epl open" },
    { "<leader>dl",  function() require("dap").run_last() end,          desc = "  [D]ap Run [L]ast" },
    {
      "<leader>dq",
      function()
        local dap = require("dap")
        local session = dap.session()
        if session and session.config and session.config.request == "attach" then
          dap.disconnect({ terminateDebuggee = false })
          vim.notify("🔌 DAP detached cleanly. Server is still running!", vim.log.levels.INFO)
        else
          dap.terminate()
        end
        local ok, dapui = pcall(require, "dapui")
        if ok then
          dapui.close()
        end
      end,
      desc = "  [D]ap [Q]uit (safe detach without killing server)",
    },
    {
      "<leader>dx",
      function()
        local dap = require("dap")
        dap.disconnect({ terminateDebuggee = false })
        local ok, dapui = pcall(require, "dapui")
        if ok then
          dapui.close()
        end
        vim.notify("🔌 DAP disconnected. Server is still running!", vim.log.levels.INFO)
      end,
      desc = "  [D]ap Disconnect / Detach (keeps server alive)",
    },
  },

  config = function()
    local dap = require("dap")

    dap.defaults.fallback.focus_terminal = true

    vim.fn.sign_define("DapBreakpoint", {
      text = "●",
      texthl = "DiagnosticError",
      linehl = "",
      numhl = "",
    })

    vim.fn.sign_define("DapBreakpointCondition", {
      text = "◆",
      texthl = "DiagnosticWarn",
      linehl = "",
      numhl = "",
    })

    vim.fn.sign_define("DapLogPoint", {
      text = "◉",
      texthl = "DiagnosticInfo",
      linehl = "",
      numhl = "",
    })

    vim.fn.sign_define("DapStopped", {
      text = "→",
      texthl = "DiagnosticOk",
      linehl = "Visual",
      numhl = "DiagnosticOk",
    })

    vim.fn.sign_define("DapBreakpointRejected", {
      text = "○",
      texthl = "DiagnosticHint",
      linehl = "",
      numhl = "",
    })
  end,
}
