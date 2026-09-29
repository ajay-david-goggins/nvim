return {
  before_init = function(_, config)
   local cwd = config.root_dir or vim.fn.getcwd()
    local candidates = {
      cwd .. "/env/bin/python",
      cwd .. "/../env/bin/python",
      cwd .. "/.venv/bin/python",
    }
    for _, p in ipairs(candidates) do
      if vim.fn.executable(p) == 1 then
        config.settings.python.pythonPath = p
        break
      end
    end
  end,
  settings = {
    python = {
      pythonPath = vim.fn.expand("~/.calone/fcalone/env/bin/python"),
      analysis = {
        typeCheckingMode = "basic", -- "off" | "basic" | "strict"
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
        diagnosticSeverityOverrides = {
          reportMissingTypeStubs = "none",
          reportUnusedImport = "warning",
          reportUnusedVariable = "warning",
          reportPrivateUsage = "none",
          reportAttributeAccessIssue = "warning",
        },
      },
    },
  },
}
