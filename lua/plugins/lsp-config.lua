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
                    "ts_ls",       -- ✅ KEEP this
                    "jdtls",
                    "html",
                    "cssls",
                    "clangd",
                    "emmet_ls",
                    "angularls",
                    "eslint",      -- ✅ ESLint LSP
                },
            })
        end,
    },

    -- DAP Support
    {
        "jay-babu/mason-nvim-dap.nvim",
        config = function()
            require("mason-nvim-dap").setup({
                ensure_installed = { "java-debug-adapter", "java-test" }
            })
        end,
    },

    -- Java LSP (JDTLS)
    {
        "mfussenegger/nvim-jdtls",
        dependencies = {
            "mfussenegger/nvim-dap",
        },
    },

    -- LSP Setup
    {
        "neovim/nvim-lspconfig",
        config = function()
            local lspconfig = require("lspconfig")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            local util = require("lspconfig.util")

            -- Standard LSPs
            lspconfig.lua_ls.setup({ capabilities = capabilities })
            lspconfig.ts_ls.setup({ capabilities = capabilities })
            lspconfig.html.setup({ capabilities = capabilities })
            lspconfig.cssls.setup({ capabilities = capabilities })
            lspconfig.clangd.setup({ capabilities = capabilities })

            -- Emmet
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
                            ["bem.enabled"] = true
                        }
                    }
                }
            })

            -- Angular
            lspconfig.angularls.setup({
                capabilities = capabilities,
                root_dir = util.root_pattern("angular.json", "package.json", "nx.json", ".git"),
                filetypes = { "typescript", "html", "scss", "css" },
                settings = {
                    angular = {
                        strictTemplates = true
                    }
                }
            })

            -- ESLint with flat config support
            lspconfig.eslint.setup({
                capabilities = capabilities,
                on_attach = function(_, bufnr)
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = bufnr,
                        command = "EslintFixAll", -- Requires eslint.nvim or formatter
                    })
                end,
                settings = {
                    workingDirectory = { mode = "auto" },
                    experimental = {
                        useFlatConfig = true, -- ✅ For eslint.config.mjs
                    },
                },
                root_dir = util.root_pattern(
                    "eslint.config.mjs",
                    ".eslintrc",
                    ".eslintrc.js",
                    ".eslintrc.json",
                    ".eslintrc.cjs",
                    "package.json",
                    ".git"
                ),
            })

            -- LSP Keymaps
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

