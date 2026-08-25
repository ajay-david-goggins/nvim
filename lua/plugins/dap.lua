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
    { "<leader>dc",  function() require("dap").continue() end,          desc = "  [D]ap [C]ontinue / Start" },
    { "<leader>dso", function() require("dap").step_over() end,         desc = "  [D]ap [S]tep [O]ver" },
    { "<leader>dsi", function() require("dap").step_into() end,         desc = "  [D]ap [S]tep [I]nto" },
    { "<leader>dsO", function() require("dap").step_out() end,          desc = "  [D]ap [S]tep [O]ut" },
    { "<leader>dr",  function() require("dap").repl.open() end,         desc = "  [D]ap [R]epl open" },
    { "<leader>dl",  function() require("dap").run_last() end,          desc = "  [D]ap Run [L]ast" },
    { "<leader>dq",  function() require("dap").terminate() end,         desc = "  [D]ap [Q]uit/terminate" },
  },

  config = function()
    local dap = require("dap")

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
