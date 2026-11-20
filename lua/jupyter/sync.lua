-- =============================================================================
-- jupyter/sync.lua · Transparent Two-Way Sync (.ipynb <-> py:percent)
--
-- Uses the Jupytext CLI via stdin/stdout streams:
-- - Zero temporary files created on disk (protects against filesystem pollution).
-- - Preserves existing cell outputs and execution metadata via `--update`.
-- - Handles new and existing notebooks seamlessly.
-- =============================================================================

local M = {}

---Check if jupytext CLI is available
---@return boolean
local function check_executable()
  if vim.fn.executable("jupytext") == 1 then
    return true
  end
  vim.notify(
    "jupytext CLI not found in PATH.\nInstall via: uv tool install jupytext",
    vim.log.levels.ERROR,
    { title = "Jupyter Sync" }
  )
  return false
end

local function set_skeleton(bufnr)
  local skeleton = {
    "# %%",
    "# New Jupyter Notebook",
    "",
  }
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, skeleton)
end

---Read .ipynb file and convert into Python percent format buffer
---@param bufnr integer
---@param filepath string
function M.read_ipynb(bufnr, filepath)
  if not check_executable() then
    return
  end

  local fullpath = vim.fn.fnamemodify(filepath, ":p")
  local exists = vim.fn.filereadable(fullpath) == 1
  local size = exists and vim.fn.getfsize(fullpath) or 0

  local loaded = false

  if exists and size > 0 then
    local res = vim.system(
      { "jupytext", "--to", "py:percent", fullpath, "-o", "-" },
      { text = true }
    ):wait()

    if res.code == 0 and res.stdout and res.stdout ~= "" then
      local lines = vim.split(res.stdout, "\n", { plain = true })
      if #lines > 0 and lines[#lines] == "" then
        table.remove(lines)
      end
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      loaded = true
    else
      -- If jupytext failed on existing file (e.g. corrupt JSON or plain text percent format)
      local raw_lines = vim.fn.readfile(fullpath)
      if #raw_lines > 0 and (raw_lines[1]:match("^# %%%%") or raw_lines[1]:match("^import") or raw_lines[1]:match("^from")) then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, raw_lines)
        loaded = true
      else
        vim.notify(
          "Notebook file is empty or invalid JSON; initialized blank notebook template.",
          vim.log.levels.WARN,
          { title = "Jupyter Read" }
        )
      end
    end
  end

  if not loaded then
    set_skeleton(bufnr)
  end

  -- Configure buffer attributes
  vim.bo[bufnr].filetype = "python"
  vim.bo[bufnr].buftype = ""
  vim.bo[bufnr].modified = false
  vim.b[bufnr].is_ipynb = true
  vim.b[bufnr].ipynb_filepath = fullpath

  -- Reset undo history so opening doesn't dirty the undo tree
  local ul = vim.bo[bufnr].undolevels
  vim.bo[bufnr].undolevels = -1
  vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, {})
  vim.bo[bufnr].undolevels = ul

  -- Trigger BufReadPost so treesitter, diagnostics, and LSP handlers attach
  vim.api.nvim_exec_autocmds("BufReadPost", { buffer = bufnr })
end

---Write Python percent format buffer back into .ipynb JSON format
---@param bufnr integer
---@param filepath string
function M.write_ipynb(bufnr, filepath)
  if not check_executable() then
    return
  end

  local fullpath = vim.fn.fnamemodify(filepath, ":p")
  local exists = vim.fn.filereadable(fullpath) == 1
  local size = exists and vim.fn.getfsize(fullpath) or 0

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n") .. "\n"

  local success = false
  if exists and size > 0 then
    -- Try --update first to preserve existing outputs, metadata, and execution counts
    local res = vim.system(
      { "jupytext", "--from", "py:percent", "--to", "ipynb", "--update", "-o", fullpath, "-" },
      { stdin = content, text = true }
    ):wait()
    if res.code == 0 then
      success = true
    end
  end

  -- Fallback to fresh write if file didn't exist, was empty, or --update failed (corrupt JSON)
  if not success then
    local tmp_file = vim.fn.tempname() .. ".ipynb"
    local res = vim.system(
      { "jupytext", "--from", "py:percent", "--to", "ipynb", "-o", tmp_file, "-" },
      { stdin = content, text = true }
    ):wait()
    if res.code == 0 and vim.fn.filereadable(tmp_file) == 1 then
      local mv_res = vim.system({ "mv", "-f", tmp_file, fullpath }):wait()
      if mv_res.code == 0 then
        success = true
      end
    end
  end

  if not success then
    vim.notify(
      "Failed to write notebook format to disk.",
      vim.log.levels.ERROR,
      { title = "Jupyter Write Error" }
    )
    return
  end

  vim.bo[bufnr].modified = false
  vim.api.nvim_exec_autocmds("BufWritePost", { buffer = bufnr })
  vim.notify("󰄬 Notebook saved: " .. vim.fn.fnamemodify(fullpath, ":t"), vim.log.levels.INFO, { title = "Jupyter" })
end

return M
