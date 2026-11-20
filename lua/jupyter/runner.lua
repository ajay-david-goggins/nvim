-- =============================================================================
-- jupyter/runner.lua · Interactive Cell Execution (Molten Kernel & REPL Fallback)
--
-- Features:
-- - Primary backend: Molten Jupyter Kernel (true inline VS Code notebook output)
-- - Automatic kernel detection and initialization
-- - Code cell detection (# %% or # <codecell>)
-- - Fallback Neovim terminal REPL using clean bracketed paste (no %cpaste -q noise)
-- - Cell navigation (next/prev) and insertion (above/below)
-- =============================================================================

local M = {}

local CELL_PATTERN = "^%s*#%s*%%%%"
local MD_CELL_PATTERN = "^%s*#%s*%%%%%s*%[markdown%]"

local state = {
  repl_buf = nil,
  repl_win = nil,
  repl_job = nil,
  is_ipython = false,
}

---Check if Molten plugin is installed and available
---@return boolean
local function has_molten()
  return vim.fn.exists(":MoltenInit") == 2
end

---Ensure a Molten kernel is initialized for the current buffer
---@param bufnr? integer
---@return boolean
---Ensure a Molten kernel is initialized for the current buffer
---@param bufnr? integer
---@return boolean
local function ensure_molten_kernel(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.b[bufnr].molten_kernel_id then
    return true
  end

  local runtime_dir = vim.fn.expand("~/.local/share/jupyter/runtime")
  if vim.fn.isdirectory(runtime_dir) == 0 then
    vim.fn.mkdir(runtime_dir, "p")
  end

  -- Check if a kernel is already running: reuse it to prevent ghost kernel pile-ups!
  local running = vim.fn.MoltenRunningKernels()
  if type(running) == "table" and #running > 0 then
    pcall(vim.cmd, "MoltenInit shared " .. running[1])
  else
    vim.notify("󱐋 Initializing Jupyter kernel for notebook...", vim.log.levels.INFO, { title = "Jupyter" })
    local ok = pcall(vim.cmd, "MoltenInit python3")
    if not ok then
      pcall(vim.cmd, "MoltenInit")
    end
  end

  return vim.b[bufnr].molten_kernel_id ~= nil
end

---Find Python binary from active venv, conda, upward traversal, or PATH
---@return string bin, boolean is_ipython
local function detect_python()
  -- 1. Check active shell environment
  local venv = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
  if venv and venv ~= "" then
    local ipy = venv .. "/bin/ipython"
    if vim.fn.executable(ipy) == 1 then
      return ipy, true
    end
    local py = venv .. "/bin/python"
    if vim.fn.executable(py) == 1 then
      return py, false
    end
  end

  -- 2. Traverse upwards for .venv or venv
  local cur = vim.fn.expand("%:p:h")
  if cur and cur ~= "" then
    for _ = 1, 10 do
      for _, name in ipairs({ ".venv", "venv", "env" }) do
        local ipy = cur .. "/" .. name .. "/bin/ipython"
        if vim.fn.executable(ipy) == 1 then
          return ipy, true
        end
        local py = cur .. "/" .. name .. "/bin/python"
        if vim.fn.executable(py) == 1 then
          return py, false
        end
      end
      local parent = vim.fs.dirname(cur)
      if not parent or parent == cur then
        break
      end
      cur = parent
    end
  end

  -- 3. System / PATH lookup
  if vim.fn.executable("ipython") == 1 then
    return "ipython", true
  end
  if vim.fn.executable("python3") == 1 then
    return "python3", false
  end

  return "python", false
end

---Check if the REPL terminal job is alive
---@return boolean
local function is_repl_alive()
  if state.repl_buf and vim.api.nvim_buf_is_valid(state.repl_buf) and state.repl_job then
    local ok, res = pcall(vim.fn.jobwait, { state.repl_job }, 0)
    if ok and res[1] == -1 then
      return true
    end
  end
  return false
end

---Ensure the fallback REPL terminal window and job are open
---@param focus? boolean
---@return integer? job_id
local function ensure_repl(focus)
  if is_repl_alive() then
    local win_valid = state.repl_win and vim.api.nvim_win_is_valid(state.repl_win)
    if not win_valid then
      vim.cmd("botright 12split")
      state.repl_win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(state.repl_win, state.repl_buf)
      if not focus then
        vim.cmd("wincmd p")
      end
    elseif focus then
      vim.api.nvim_set_current_win(state.repl_win)
    end
    return state.repl_job
  end

  -- Spawn new terminal REPL
  local cur_win = vim.api.nvim_get_current_win()
  local bin, is_ipy = detect_python()
  state.is_ipython = is_ipy

  vim.cmd("botright 12split")
  state.repl_win = vim.api.nvim_get_current_win()

  local cmd = is_ipy and (bin .. " --no-autoindent --colors=neutral") or bin
  vim.cmd.terminal(cmd)
  state.repl_buf = vim.api.nvim_get_current_buf()
  state.repl_job = vim.b[state.repl_buf].terminal_job_id

  vim.bo[state.repl_buf].bufhidden = "hide"
  vim.bo[state.repl_buf].filetype = "jupyter_repl"

  vim.notify("󱐋 Jupyter REPL started using " .. vim.fn.fnamemodify(bin, ":t"), vim.log.levels.INFO, { title = "Jupyter" })

  if not focus then
    vim.api.nvim_set_current_win(cur_win)
  end

  return state.repl_job
end

---Send code block directly to terminal REPL (fallback)
---@param code string
function M.send_to_repl(code)
  if not code or code:match("^%s*$") then
    return
  end

  -- Tmux pane integration
  if vim.g.jupyter_runner_target == "tmux" and vim.env.TMUX then
    local target_pane = vim.g.jupyter_tmux_target or "{right-of}"
    vim.fn.system({ "tmux", "load-buffer", "-" }, code .. "\n")
    vim.fn.system({ "tmux", "paste-buffer", "-d", "-t", target_pane })
    return
  end

  local job_id = ensure_repl(false)
  if not job_id then
    return
  end

  -- Use clean bracketed paste mode (NO %cpaste -q spam in REPL)
  local payload = "\27[200~" .. code .. "\27[201~\n"
  vim.api.nvim_chan_send(job_id, payload)

  if state.repl_win and vim.api.nvim_win_is_valid(state.repl_win) and state.repl_buf and vim.api.nvim_buf_is_valid(state.repl_buf) then
    local line_count = vim.api.nvim_buf_line_count(state.repl_buf)
    pcall(vim.api.nvim_win_set_cursor, state.repl_win, { line_count, 0 })
  end
end

---Get current cell start and end line (1-indexed)
---@param bufnr? integer
---@param lnum? integer
---@return integer start_line, integer end_line, boolean is_markdown
function M.get_cell_bounds(bufnr, lnum)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  lnum = lnum or vim.api.nvim_win_get_cursor(0)[1]
  local total = vim.api.nvim_buf_line_count(bufnr)

  local start_line = 1
  local end_line = total
  local is_markdown = false

  -- Search backwards for start of cell
  for l = lnum, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
    if line:match(CELL_PATTERN) then
      start_line = l
      if line:match(MD_CELL_PATTERN) then
        is_markdown = true
      end
      break
    end
  end

  -- Search forwards for end of cell
  for l = start_line + 1, total do
    local line = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
    if line:match(CELL_PATTERN) then
      end_line = l - 1
      break
    end
  end

  return start_line, end_line, is_markdown
end

---Extract code from cell bounds, stripping header marker
---@param bufnr integer
---@param start_line integer
---@param end_line integer
---@return string
local function get_cell_code(bufnr, start_line, end_line)
  local raw_lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  local code_lines = {}

  for i, line in ipairs(raw_lines) do
    if i == 1 and line:match(CELL_PATTERN) then
      -- Omit cell delimiter line itself
    else
      table.insert(code_lines, line)
    end
  end

  return table.concat(code_lines, "\n")
end

---Run the current cell
function M.run_cell()
  local bufnr = vim.api.nvim_get_current_buf()
  local start_l, end_l, is_md = M.get_cell_bounds(bufnr)

  if is_md then
    vim.notify("Markdown cell: skipped execution", vim.log.levels.INFO, { title = "Jupyter" })
    return
  end

  -- 1. Preferred: Molten Jupyter Kernel (VS Code inline notebook style)
  if has_molten() then
    ensure_molten_kernel(bufnr)
    -- Determine actual code range without empty outer edges
    local eval_start = start_l
    local first_line = vim.api.nvim_buf_get_lines(bufnr, start_l - 1, start_l, false)[1] or ""
    if first_line:match(CELL_PATTERN) and start_l < end_l then
      eval_start = start_l + 1
    end

    local ok, err = pcall(vim.fn.MoltenEvaluateRange, eval_start, end_l)
    if not ok then
      vim.notify("Molten evaluation failed: " .. tostring(err), vim.log.levels.ERROR, { title = "Jupyter" })
    end
    return
  end

  -- 2. Fallback: Terminal REPL
  local code = get_cell_code(bufnr, start_l, end_l)
  M.send_to_repl(code)
end

---Run the current cell and advance to the next cell (Shift+Enter behavior)
function M.run_cell_and_move()
  M.run_cell()
  M.next_cell()
end

---Run the currently visually selected text or current line
---@param mode? string
function M.run_selection(mode)
  if has_molten() then
    local bufnr = vim.api.nvim_get_current_buf()
    ensure_molten_kernel(bufnr)
    vim.cmd("MoltenEvaluateVisual")
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local code = ""

  if mode == "v" or mode == "V" or mode == "\22" then
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_pos[2] - 1, end_pos[2], false)
    if #lines > 0 then
      code = table.concat(lines, "\n")
    end
  else
    local cur_line = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, cur_line - 1, cur_line, false)[1] or ""
    code = line
  end

  M.send_to_repl(code)
end

---Run the current line in normal mode
function M.run_line()
  if has_molten() then
    local bufnr = vim.api.nvim_get_current_buf()
    ensure_molten_kernel(bufnr)
    vim.cmd("MoltenEvaluateLine")
    return
  end

  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, cur_line - 1, cur_line, false)[1] or ""
  M.send_to_repl(line)
end

---Jump to the next cell
function M.next_cell()
  local bufnr = vim.api.nvim_get_current_buf()
  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  local total = vim.api.nvim_buf_line_count(bufnr)

  for l = cur_line + 1, total do
    local line = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
    if line:match(CELL_PATTERN) then
      vim.api.nvim_win_set_cursor(0, { l, 0 })
      return
    end
  end
  vim.notify("Already at last cell", vim.log.levels.INFO, { title = "Jupyter" })
end

---Jump to the previous cell
function M.prev_cell()
  local bufnr = vim.api.nvim_get_current_buf()
  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  local start = cur_line - 1

  for l = start, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
    if line:match(CELL_PATTERN) then
      vim.api.nvim_win_set_cursor(0, { l, 0 })
      return
    end
  end
  vim.notify("Already at first cell", vim.log.levels.INFO, { title = "Jupyter" })
end

---Insert a new cell below the current cell
function M.add_cell_below()
  local bufnr = vim.api.nvim_get_current_buf()
  local _, end_l = M.get_cell_bounds(bufnr)

  vim.api.nvim_buf_set_lines(bufnr, end_l, end_l, false, { "", "# %%", "" })
  vim.api.nvim_win_set_cursor(0, { end_l + 3, 0 })
  vim.cmd("startinsert")
end

---Insert a new cell above the current cell
function M.add_cell_above()
  local bufnr = vim.api.nvim_get_current_buf()
  local start_l = M.get_cell_bounds(bufnr)
  local insert_at = math.max(0, start_l - 1)

  vim.api.nvim_buf_set_lines(bufnr, insert_at, insert_at, false, { "# %%", "", "" })
  vim.api.nvim_win_set_cursor(0, { insert_at + 2, 0 })
  vim.cmd("startinsert")
end

---Explicitly initialize a Jupyter kernel
function M.init_kernel()
  if has_molten() then
    vim.cmd("MoltenInit")
  else
    M.toggle_repl()
  end
end

---Open / focus floating output window
function M.show_output()
  if has_molten() then
    pcall(vim.cmd, "noautocmd MoltenEnterOutput")
  else
    M.toggle_repl()
  end
end

---Hide floating output window
function M.hide_output()
  if has_molten() then
    pcall(vim.cmd, "MoltenHideOutput")
  end
end

---Delete current cell execution output
function M.delete_output()
  if has_molten() then
    pcall(vim.cmd, "MoltenDelete")
  end
end

---Toggle terminal REPL window
function M.toggle_repl()
  if is_repl_alive() and state.repl_win and vim.api.nvim_win_is_valid(state.repl_win) then
    vim.api.nvim_win_close(state.repl_win, true)
    state.repl_win = nil
  else
    ensure_repl(true)
  end
end

---Restart REPL or active kernel
function M.restart_repl()
  local bufnr = vim.api.nvim_get_current_buf()
  if has_molten() and vim.b[bufnr].molten_kernel_id then
    pcall(vim.cmd, "MoltenRestart!")
    vim.notify("󰑐 Jupyter kernel restarted", vim.log.levels.INFO, { title = "Jupyter" })
    return
  end

  if state.repl_job then
    pcall(vim.fn.jobstop, state.repl_job)
    state.repl_job = nil
  end
  if state.repl_buf and vim.api.nvim_buf_is_valid(state.repl_buf) then
    vim.api.nvim_buf_delete(state.repl_buf, { force = true })
    state.repl_buf = nil
  end
  state.repl_win = nil
  ensure_repl(true)
  vim.notify("󰑐 Jupyter REPL restarted", vim.log.levels.INFO, { title = "Jupyter" })
end

return M
