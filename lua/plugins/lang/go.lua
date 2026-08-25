-- =============================================================================
-- lang/go.lua · Go-specific keymaps + nvim-dap-go.
-- gopls settings now live in nvim/lsp/gopls.lua.
-- goimports/gofumpt formatting now lives in plugins/conform.lua.
-- Tool ensure_installed (gopls/goimports/delve/...) lives in plugins/mason.lua.
-- =============================================================================
return {
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {
      dap_configurations = {
        { type = "go", name = "Debug", request = "launch", program = "${file}" },
        { type = "go", name = "Debug Package", request = "launch", program = "${fileDirname}" },
        { type = "go", name = "Attach (remote)", request = "attach", mode = "remote", remotePath = "${workspaceFolder}" },
      },
      delve = {
        path = vim.fn.exepath("dlv"),
        initialize_timeout_sec = 20,
        port = "${port}",
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("GoLspAttach", { clear = true }),
        pattern = "*.go",
        callback = function(args)
          local buf = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end

          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
          end

          map("n", "<leader>go", function()
            vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
          end, "󰶮  Go Organize Imports")

          map("n", "<leader>gf", function()
            vim.lsp.buf.code_action({ context = { only = { "refactor.rewrite" } } })
          end, "󰙅  Go Fill Struct")

          map("n", "<leader>gt", function()
            local tag = vim.fn.input("Tag (e.g. json): ")
            if tag == "" then return end
            local cmd = string.format(
              "gomodifytags -file %s -line %d -add-tags %s -transform camelcase",
              vim.fn.expand("%"), vim.fn.line("."), tag
            )
            local result = vim.fn.system(cmd)
            if vim.v.shell_error == 0 then
              vim.cmd("edit!")
            else
              vim.notify("gomodifytags error:\n" .. result, vim.log.levels.ERROR)
            end
          end, "󰓼  Go Modify Tags")

          map("n", "<leader>gi", function()
            local recv = vim.fn.input("Receiver (e.g. r *MyType): ")
            local iface = vim.fn.input("Interface (e.g. io.Reader): ")
            if recv == "" or iface == "" then return end
            local result = vim.fn.system(string.format("impl '%s' %s", recv, iface))
            if vim.v.shell_error == 0 then
              local lines = vim.split(result, "\n", { trimempty = true })
              vim.api.nvim_buf_set_lines(buf, vim.fn.line("."), vim.fn.line("."), false, lines)
            else
              vim.notify("impl error:\n" .. result, vim.log.levels.ERROR)
            end
          end, "󰡱  Go Implement Interface")

          -- Test runners keep their own dt/dT letters (language-specific
          -- concept, no equivalent in the unified DAP scheme below).
          local ok_go, dap_go = pcall(require, "dap-go")
          if ok_go then
            map("n", "<leader>dt", dap_go.debug_test, "󰙨  [D]ap [T]est nearest")
            map("n", "<leader>dT", dap_go.debug_last_test, "󰙨  [D]ap [T]est last")
          end

          -- Unified DAP scheme — identical letters across every language,
          -- see lang/python.lua for the shared-namespace rationale.
          -- local ok_dap, dap = pcall(require, "dap")
          -- if ok_dap then
          --   map("n", "<leader>db",  dap.toggle_breakpoint, "󰴿  [D]ap [B]reakpoint toggle")
          --   map("n", "<leader>dc",  dap.continue,          "󰐊  [D]ap [C]ontinue")
          --   map("n", "<leader>dso", dap.step_over,         "󰆷  [D]ap [S]tep [O]ver")
          --   map("n", "<leader>dsi", dap.step_into,         "󰆹  [D]ap [S]tep [I]nto")
          --   map("n", "<leader>dsO", dap.step_out,          "󰆸  [D]ap [S]tep [O]ut")
          --   map("n", "<leader>dr",  dap.repl.open,         "  [D]ap [R]epl open")
          --   map("n", "<leader>dl",  dap.run_last,          "  [D]ap Run [L]ast")
          --   map("n", "<leader>dq",  dap.terminate,         "󰓛  [D]ap [Q]uit/terminate")
          -- end
        end,
      })
    end,
  },
}
