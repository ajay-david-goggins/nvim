local function find_venv_python(start_dir)
  -- 1. Check active virtual environment from shell
  local venv = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
  if venv and venv ~= "" then
    local bin = venv .. "/bin/python"
    if vim.fn.executable(bin) == 1 then
      return bin, venv
    end
    local win_bin = venv .. "/Scripts/python.exe"
    if vim.fn.executable(win_bin) == 1 then
      return win_bin, venv
    end
  end

  -- 2. Traverse upwards from start_dir looking for virtualenvs
  local venv_names = { "env", ".venv", "venv", ".env" }
  local cur = start_dir
  for _ = 1, 15 do
    for _, name in ipairs(venv_names) do
      local p = cur .. "/" .. name .. "/bin/python"
      if vim.fn.executable(p) == 1 then
        return p, cur
      end
      local win_p = cur .. "/" .. name .. "/Scripts/python.exe"
      if vim.fn.executable(win_p) == 1 then
        return win_p, cur
      end
    end
    local parent = vim.fs.dirname(cur)
    if not parent or parent == cur then
      break
    end
    cur = parent
  end

  return nil, nil
end

local function find_bench_root(start_dir)
  local cur = start_dir
  for _ = 1, 15 do
    local has_apps = vim.fn.isdirectory(cur .. "/apps") == 1
    local has_sites = vim.fn.isdirectory(cur .. "/sites") == 1
    local has_procfile = vim.fn.filereadable(cur .. "/Procfile") == 1
    if has_apps and (has_sites or has_procfile) then
      return cur
    end
    local parent = vim.fs.dirname(cur)
    if not parent or parent == cur then
      break
    end
    cur = parent
  end
  return nil
end

return {
  before_init = function(_, config)
    local cwd = config.root_dir or vim.fn.getcwd()
    local py, venv_root = find_venv_python(cwd)
    if not py then
      py, venv_root = find_venv_python(vim.fn.getcwd())
    end

    if py then
      config.settings.python.pythonPath = py
    end

    -- Dynamically discover bench apps (Frappe bench or any multi-app layout)
    local bench_root = find_bench_root(cwd) or (venv_root and find_bench_root(venv_root))
    if bench_root and vim.fn.isdirectory(bench_root .. "/apps") == 1 then
      local extra = {}
      local apps = vim.fn.globpath(bench_root .. "/apps", "*", false, true)
      for _, app in ipairs(apps) do
        if vim.fn.isdirectory(app) == 1 then
          table.insert(extra, app)
        end
      end
      if #extra > 0 then
        config.settings.python.analysis = config.settings.python.analysis or {}
        config.settings.python.analysis.extraPaths = extra
      end
    end
  end,
  settings = {
    python = {
      pythonPath = vim.fn.exepath("python3") ~= "" and vim.fn.exepath("python3") or "python3",
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
