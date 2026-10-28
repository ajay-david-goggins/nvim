-- =============================================================================
-- lua/plugins/postman.lua
-- Open-Source Postman Alternative & HTTP Testing Suite for Neovim
-- =============================================================================

return {
  -- 1. Native Postman Collection & Environment Engine
  {
    dir = vim.fn.stdpath("config") .. "/lua/postman",
    name = "nvim-postman",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    cmd = {
      "PostmanRun",
      "PostmanSelectCollection",
      "PostmanSelectEnv",
      "PostmanEditEnv",
      "PostmanModifyVar",
      "PostmanResponse",
      "PostmanVariables",
      "PostmanExtractVar",
      "PostmanExportHttp",
      "PostmanSetVar",
    },
    keys = {
      { "<leader>pr", function() require("postman").run() end, desc = "  [P]ostman [R]un request (Telescope)" },
      { "<leader>pc", function() require("postman").select_collection() end, desc = "  [P]ostman select [C]ollection" },
      { "<leader>pe", function() require("postman").select_env() end, desc = "  [P]ostman select [E]nvironment" },
      { "<leader>pE", function() require("postman").edit_env() end, desc = "  [P]ostman [E]dit environment file (split)" },
      { "<leader>pm", function() require("postman").modify_var() end, desc = "  [P]ostman [M]odify variable interactively" },
      { "<leader>pw", function() require("postman").studio() end, desc = "  [P]ostman [W]orkspace / Studio (edit payload)" },
      { "<leader>ph", function() require("postman").history() end, desc = "  [P]ostman [H]istory browser" },
      { "<leader>pv", function() require("postman").view_response() end, desc = "  [P]ostman [V]iew last response" },
      { "<leader>px", function() require("postman").extract_variable() end, desc = "  [P]ostman e[X]tract var from response" },
      { "<leader>p?", function() require("postman").show_variables() end, desc = "  [P]ostman show active variables" },
    },
    config = function()
      require("postman").setup({
        insecure = true, -- Allow self-signed dev certificates
        timeout = 30,    -- 30s timeout
      })
    end,
  },
}
