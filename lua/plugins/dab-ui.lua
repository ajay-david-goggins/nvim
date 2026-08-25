-- =============================================================================
-- =============================================================================
-- dap-ui.lua · nvim-dap-ui + nvim-dap-virtual-text
--
-- Auto opens/closes with debug session.
-- Extras only — core dap keys (b/c/so/si/sO/r/l/q) live in plugins/dap.lua.
-- These letters (u/e/E/w/S/f/R) deliberately don't prefix-collide with core.
-- =============================================================================

return {
  -- =========================================================================
  -- nvim-dap-ui
  -- =========================================================================
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    lazy = true,

    keys = {
      -- UI toggle
      {
        "<leader>du",
        function() require("dapui").toggle() end,
        desc = "  [D]ap [U]I toggle",
      },

      -- Evaluate expression under cursor / selection
      {
        "<leader>de",
        function() require("dapui").eval() end,
        mode = { "n", "v" },
        desc = "  [D]ap [E]val",
      },
      {
        "<leader>dE",
        function()
          require("dapui").eval(vim.fn.input("Expression: "))
        end,
        desc = "  [D]ap [E]val expression",
      },

      -- Floating elements
      {
        "<leader>dw",
        function() require("dapui").float_element("watches", { enter = true }) end,
        desc = "  [D]ap [W]atches float",
      },
      {
        "<leader>dS",
        function() require("dapui").float_element("scopes", { enter = true }) end,
        desc = "  [D]ap [S]copes float",
      },
      {
        "<leader>df",
        function() require("dapui").float_element("stacks", { enter = true }) end,
        desc = "  [D]ap stack [F]rames float",
      },
      {
        "<leader>dR",
        function() require("dapui").float_element("repl", { enter = true }) end,
        desc = "  [D]ap [R]EPL float",
      },
    },

    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup({
        controls = {
          enabled = true,
          element = "repl",
        },
        floating = {
          border = "rounded",
          mappings = {
            close = { "q", "<Esc>" },
          },
        },
        mappings = {
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          edit = "e",
          repl = "r",
          toggle = "t",
        },
      })

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },

  -- =========================================================================
  -- nvim-dap-virtual-text
  -- =========================================================================
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    lazy = true,
    opts = {
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = true,
      show_stop_reason = true,
      commented = false,
      only_first_definition = true,
      all_references = false,
      virt_text_pos = "eol",
      all_frames = false,
    },
  },
}
