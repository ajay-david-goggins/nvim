-- =============================================================================
-- jupyter/init.lua · Native, Lightweight Jupyter (.ipynb) Engine for Neovim
--
-- Exposes:
-- - Bidirectional sync via sync.lua (BufReadCmd / BufWriteCmd for *.ipynb)
-- - REPL and cell evaluation via runner.lua
-- =============================================================================

local sync = require("jupyter.sync")
local runner = require("jupyter.runner")

local M = {}

-- Forward public methods
M.read_ipynb = sync.read_ipynb
M.write_ipynb = sync.write_ipynb

M.run_cell = runner.run_cell
M.run_cell_and_move = runner.run_cell_and_move
M.run_line = runner.run_line
M.run_selection = runner.run_selection
M.next_cell = runner.next_cell
M.prev_cell = runner.prev_cell
M.add_cell_above = runner.add_cell_above
M.add_cell_below = runner.add_cell_below
M.toggle_repl = runner.toggle_repl
M.restart_repl = runner.restart_repl

---Setup Jupyter integration
---@param opts? table
function M.setup(opts)
  opts = opts or {}
  if opts.target then
    vim.g.jupyter_runner_target = opts.target
  end

  -- Explicitly tell Neovim that .ipynb buffers represent Python code
  vim.filetype.add({
    extension = {
      ipynb = "python",
    },
  })

  local augroup = vim.api.nvim_create_augroup("JupyterNativeSync", { clear = true })

  -- Handle reading *.ipynb (both existing and new notebooks)
  vim.api.nvim_create_autocmd({ "BufReadCmd", "FileReadCmd", "BufNewFile" }, {
    group = augroup,
    pattern = "*.ipynb",
    callback = function(args)
      sync.read_ipynb(args.buf, args.match)
    end,
  })

  -- Handle writing *.ipynb
  vim.api.nvim_create_autocmd({ "BufWriteCmd", "FileWriteCmd" }, {
    group = augroup,
    pattern = "*.ipynb",
    callback = function(args)
      sync.write_ipynb(args.buf, args.match)
    end,
  })
end

return M
