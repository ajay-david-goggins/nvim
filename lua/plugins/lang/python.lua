-- =============================================================================
-- lang/python.lua · debugpy DAP only.
-- pyright + ruff settings now live in nvim/lsp/pyright.lua and nvim/lsp/ruff.lua
-- (mason ensure_installed for both moved to plugins/mason.lua).
-- Formatting (ruff_format/ruff_organize_imports) moved to plugins/conform.lua.
-- =============================================================================
return {
  "mfussenegger/nvim-dap",
  ft = { "python" },
  config = function()
    local dap = require("dap")
    local mason_pkg = vim.fn.expand("~/.local/share/nvim/mason/packages")

    dap.adapters.python = function(cb, config)
      if config.request == "attach" then
        local host = (config.connect or config).host or "127.0.0.1"
        local port = (config.connect or config).port
        cb({ type = "server", host = host, port = port })
      else
        cb({
          type = "executable",
          command = mason_pkg .. "/debugpy/venv/bin/python",
          args = { "-m", "debugpy.adapter" },
        })
      end
    end

    local function get_python()
      local venv = vim.fn.getcwd() .. "/.venv/bin/python"
      if vim.fn.executable(venv) == 1 then return venv end
      return vim.fn.exepath("python3") or "python"
    end

    dap.configurations.python = {
      {
        type = "python",
        request = "attach",
        name = "Attach to Frappe",
        connect = { host = "127.0.0.1", port = 5678 },
        justMyCode = false,
        pathMappings = {
          {
            localRoot = vim.fn.expand("~/calone/BACKEND"),
            remoteRoot = vim.fn.expand("~/calone/BACKEND"),
          },
        },
      },
      {
        type = "python",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        pythonPath = get_python,
      },
      {
        type = "python",
        request = "launch",
        name = "Launch with args",
        program = "${file}",
        args = function()
          return vim.split(vim.fn.input("Args: "), " ", { trimempty = true })
        end,
        pythonPath = get_python,
      },
      {
        type = "python",
        request = "launch",
        name = "pytest: current file",
        module = "pytest",
        args = { "${file}", "-v" },
        pythonPath = get_python,
      },
    }

    -- ---------------------------------------------------------------------
    -- DAP keymaps — unified scheme, identical letters across every language
    -- (see lang/go.lua, lang/java.lua). <leader>d(o/p/n/Q/x/i/I/C/a/v/g/B) is
    -- Diagnostics (configs/lsp.lua, LspAttach) and shares zero letters with
    -- this set on purpose — both are buffer-local and attach to the same
    -- Python buffer, so an overlap here would silently shadow diagnostics.
    -- ---------------------------------------------------------------------
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "python",
      callback = function(args)
        local o = { buffer = args.buf, silent = true }
        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", o, { desc = desc }))
        end
        map("<leader>db",  dap.toggle_breakpoint, "  [D]ap [B]reakpoint toggle")
        map("<leader>dc",  dap.continue,           "  [D]ap [C]ontinue")
        map("<leader>dso", dap.step_over,          "  [D]ap [S]tep [O]ver")
        map("<leader>dsi", dap.step_into,          "  [D]ap [S]tep [I]nto")
        map("<leader>dsO", dap.step_out,           "  [D]ap [S]tep [O]ut")
        map("<leader>dr",  dap.repl.open,          "  [D]ap [R]epl open")
        map("<leader>dl",  dap.run_last,           "  [D]ap Run [L]ast")
        map("<leader>dq",  dap.terminate,          "  [D]ap [Q]uit/terminate")
      end,
    })
  end,
}
