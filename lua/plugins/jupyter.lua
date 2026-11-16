-- =============================================================================
-- lua/plugins/jupyter.lua
-- Native, Lightweight & Future-Proof Jupyter Notebook (.ipynb) Support
-- =============================================================================

return {
  {
    name = "nvim-jupyter",
    dir = vim.fn.stdpath("config") .. "/lua/jupyter",
    lazy = false,
    cmd = {
      "JupyterRunCell",
      "JupyterRunCellAndMove",
      "JupyterRunLine",
      "JupyterToggleRepl",
      "JupyterRestartRepl",
      "JupyterNextCell",
      "JupyterPrevCell",
      "JupyterAddCellAbove",
      "JupyterAddCellBelow",
    },
    keys = {
      { "<leader>jc", function() require("jupyter").run_cell() end, desc = "  [J]upyter run [C]ell" },
      { "<leader>jn", function() require("jupyter").run_cell_and_move() end, desc = "  [J]upyter run cell & move [N]ext (Shift-Enter)" },
      { "<leader>jl", function() require("jupyter").run_line() end, desc = "  [J]upyter run [L]ine" },
      { "<leader>jr", function() require("jupyter").run_selection(vim.fn.mode()) end, mode = { "v", "x" }, desc = "  [J]upyter [R]un selection" },
      { "<leader>ja", function() require("jupyter").add_cell_above() end, desc = "  [J]upyter add cell [A]bove" },
      { "<leader>jb", function() require("jupyter").add_cell_below() end, desc = "  [J]upyter add cell [B]elow" },
      { "<leader>jt", function() require("jupyter").toggle_repl() end, desc = "  [J]upyter [T]oggle REPL window" },
      { "<leader>jk", function() require("jupyter").restart_repl() end, desc = "  [J]upyter [K]ill / restart REPL" },
      { "]j", function() require("jupyter").next_cell() end, desc = "Next Jupyter cell" },
      { "[j", function() require("jupyter").prev_cell() end, desc = "Previous Jupyter cell" },
    },
    config = function()
      local jupyter = require("jupyter")
      jupyter.setup({
        target = "terminal", -- "terminal" (embedded split) or "tmux"
      })

      vim.api.nvim_create_user_command("JupyterRunCell", jupyter.run_cell, {})
      vim.api.nvim_create_user_command("JupyterRunCellAndMove", jupyter.run_cell_and_move, {})
      vim.api.nvim_create_user_command("JupyterRunLine", jupyter.run_line, {})
      vim.api.nvim_create_user_command("JupyterToggleRepl", jupyter.toggle_repl, {})
      vim.api.nvim_create_user_command("JupyterRestartRepl", jupyter.restart_repl, {})
      vim.api.nvim_create_user_command("JupyterNextCell", jupyter.next_cell, {})
      vim.api.nvim_create_user_command("JupyterPrevCell", jupyter.prev_cell, {})
      vim.api.nvim_create_user_command("JupyterAddCellAbove", jupyter.add_cell_above, {})
      vim.api.nvim_create_user_command("JupyterAddCellBelow", jupyter.add_cell_below, {})
    end,
  },
}
