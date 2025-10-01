return {
  -- Mason Installer
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  -- Mason LSP Installer
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "ts_ls", -- ✅ Correct name
          "html",
          "cssls",
          "emmet_ls",
          "eslint",
          "clangd",
          "jdtls", -- ✅ For Java, but handled separately
          "tailwindcss",
        },
      })
    end,
  },

  -- Mason DAP Installer (for Java debugging & testing)
  {
    "jay-babu/mason-nvim-dap.nvim",
    config = function()
      require("mason-nvim-dap").setup({
        ensure_installed = {
          "java-debug-adapter",
          "java-test",
        },
      })
    end,
  },

  -- Java Language Server (JDTLS)
  {
    "mfussenegger/nvim-jdtls",
    dependencies = {
      "mfussenegger/nvim-dap",
    },
  },

  -- Main LSP Setup
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local util = require("lspconfig.util")

      -- ✅ LUA
      lspconfig.lua_ls.setup({ capabilities = capabilities })

      -- ✅ TypeScript
      lspconfig.ts_ls.setup({ capabilities = capabilities })

      -- ✅ HTML
      lspconfig.html.setup({ capabilities = capabilities })

      -- ✅ CSS
      lspconfig.cssls.setup({ capabilities = capabilities })

      -- ✅ C/C++
      lspconfig.clangd.setup({ capabilities = capabilities })

      -- ✅ Tailwind CSS
      lspconfig.tailwindcss.setup({
        capabilities = capabilities,
        root_dir = util.root_pattern("tailwind.config.js", "postcss.config.js", "package.json", ".git"),
        filetypes = {
          "html", "javascript", "javascriptreact",
          "typescript", "typescriptreact", "php",
          "blade", "vue", "svelte",
        },
      })

      -- ✅ Emmet
      lspconfig.emmet_ls.setup({
        capabilities = capabilities,
        filetypes = {
          "html", "css", "php", "blade",
          "javascriptreact", "typescriptreact",
          "astro", "vue", "svelte",
        },
        init_options = {
          html = {
            options = {
              ["bem.enabled"] = true,
            },
          },
        },
      })

      -- ✅ Angular (use local ngserver.js)
      lspconfig.angularls.setup({
        capabilities = capabilities,
        root_dir = util.root_pattern("angular.json", "package.json", "nx.json", ".git"),
        filetypes = { "typescript", "html", "scss", "css" },
        cmd = {
          "node",
          "./node_modules/@angular/language-server/bin/ngserver.js",
          "--stdio",
          "--tsProbeLocations", "./node_modules",
          "--ngProbeLocations", "./node_modules",
        },
        on_new_config = function(new_config, _)
          new_config.cmd_env = {
            PATH = "/usr/bin:" .. os.getenv("PATH"),
          }
        end,
        settings = {
          angular = {
            strictTemplates = true,
          },
        },
      })

      -- ✅ ESLint
      lspconfig.eslint.setup({
        capabilities = capabilities,
        on_attach = function(_, bufnr)
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "EslintFixAll",
          })
        end,
        settings = {
          experimental = {
            useFlatConfig = true,
          },
          workingDirectory = {
            mode = "auto",
          },
        },
        root_dir = util.root_pattern(
          "eslint.config.mjs",
          ".eslintrc.js",
          ".eslintrc.json",
          ".eslintrc.cjs",
          "package.json",
          ".git"
        ),
      })

      -- ✅ LSP Keymaps
      vim.keymap.set("n", "<leader>ch", vim.lsp.buf.hover, { desc = "[C]ode [H]over" })
      vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition, { desc = "[C]ode [D]efinition" })
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "[C]ode [A]ction" })
      vim.keymap.set("n", "<leader>cr", require("telescope.builtin").lsp_references, { desc = "[C]ode [R]eferences" })
      vim.keymap.set("n", "<leader>ci", require("telescope.builtin").lsp_implementations, { desc = "[C]ode [I]mplementations" })
      vim.keymap.set("n", "<leader>cR", vim.lsp.buf.rename, { desc = "[C]ode [R]ename" })
      vim.keymap.set("n", "<leader>cD", vim.lsp.buf.declaration, { desc = "[C]ode [D]eclaration" })
    end,
  },
}

