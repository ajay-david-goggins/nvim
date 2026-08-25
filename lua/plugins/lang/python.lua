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
    -- Core DAP keymaps (breakpoint/continue/step/repl/run-last/terminate)
    -- are NOT redeclared here anymore — they live once, globally, in
    -- plugins/dap.lua, so Python/Go/Java all share identical letters.
    -- ---------------------------------------------------------------------

    -- ---------------------------------------------------------------------
    -- Frappe attach workflow, one command:
    --   1. :FrappeDebugServe (or <leader>dA in a python buffer) opens a
    --      terminal split at the bench root and runs debug-serve.sh, which
    --      starts `bench serve` under debugpy with --wait-for-client on
    --      127.0.0.1:5678.
    --   2. Press <leader>dc (global DAP "Continue"), pick "Attach to
    --      Frappe" — debugpy resumes bench serve and you're attached.
    -- ---------------------------------------------------------------------
    local function frappe_debug_serve()
      local bench_dir = vim.fn.expand("~/calone/BACKEND")
      local script = bench_dir .. "/debug-serve.sh"
      if vim.fn.filereadable(script) == 0 then
        vim.notify("debug-serve.sh not found: " .. script, vim.log.levels.ERROR)
        return
      end
      vim.cmd("botright vsplit | terminal")
      vim.cmd("startinsert")
      vim.fn.chansend(vim.b.terminal_job_id, "cd " .. bench_dir .. " && ./debug-serve.sh\n")
    end

    vim.api.nvim_create_user_command("FrappeDebugServe", frappe_debug_serve, {
      desc = "Start bench serve under debugpy (--wait-for-client) for Attach to Frappe",
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "python",
      callback = function(args)
        vim.keymap.set("n", "<leader>dA", frappe_debug_serve, {
          buffer = args.buf,
          silent = true,
          desc = "  [D]ap [A]ttach: start Frappe debug-serve.sh",
        })
      end,
    })
  end,
}
