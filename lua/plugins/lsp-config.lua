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
                    "lua_ls",        -- Lua
                    "ts_ls",      -- JavaScript/TypeScript
                    "jdtls",         -- Java
                    "html",          -- HTML
                    "cssls",         -- CSS
                    "clangd",        -- C/C++
                    "emmet_ls"       -- Emmet
                    -- ✨ angularls is NOT managed here
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

            -- Standard LSPs
            lspconfig.lua_ls.setup({ capabilities = capabilities })
            lspconfig.ts_ls.setup({ capabilities = capabilities }) -- ts_ls (not ts_ls)
            lspconfig.html.setup({ capabilities = capabilities })
            lspconfig.cssls.setup({ capabilities = capabilities })
            lspconfig.clangd.setup({ capabilities = capabilities })

            -- Emmet LSP
            lspconfig.emmet_ls.setup({
                capabilities = capabilities,
                filetypes = {
                    "html", "css", "php", "blade",
                    "javascriptreact", "typescriptreact"
                },
                init_options = {
                    html = {
                        options = {
                            ["bem.enabled"] = true
                        }
                    }
                }
            })

            lspconfig.angularls.setup({
                capabilities = capabilities,
                cmd = {
                    "ngserver",
                    "--stdio",
                    "--tsProbeLocations", "/usr/lib/node_modules",
                    "--ngProbeLocations", "/usr/lib/node_modules"
                },
                on_new_config = function(new_config, new_root_dir)
                    new_config.cmd = {
                        "ngserver",
                        "--stdio",
                        "--tsProbeLocations", "/usr/lib/node_modules",
                        "--ngProbeLocations", "/usr/lib/node_modules"
                    }
                end,
                root_dir = require("lspconfig").util.root_pattern("angular.json", "project.json", ".git"),
                filetypes = { "typescript", "html" },
            })
            -- 🔑 Keybindings
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

