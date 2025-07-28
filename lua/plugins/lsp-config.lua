-- ~/.config/nvim/lua/plugins/lsp-config.lua
-- This file should be returned as a table of plugin specifications for lazy.nvim

return {
    -- Mason Installer
    -- Using 'opts = {}' for lazy.nvim's automatic setup
    {
        "mason-org/mason.nvim", -- Official repository for mason.nvim
        opts = {}, -- Empty opts table tells lazy.nvim to call require("mason").setup()
    },

    -- Mason LSP Installer
    -- IMPORTANT: Pinned to v1.9.0 for compatibility with Neovim v0.10.4
    {
        "mason-org/mason-lspconfig.nvim", -- Official repository for mason-lspconfig.nvim
        tag = "v1.9.0", -- <--- THIS IS THE CRUCIAL CHANGE for Neovim v0.10.4 compatibility
        opts = {
            ensure_installed = {
                "lua_ls",
                "ts_ls",
                "jdtls",
                "html",
                "cssls",
                -- "clangd", -- Keep commented out if you don't want Mason to manage clangd installation
                "emmet_ls",
                "eslint",
            },
            -- 'automatic_enable = true' is the default for v1.x.x as well,
            -- so you don't strictly need to define it unless disabling or customizing.
            -- automatic_enable = true,
        },
        dependencies = {
            -- Explicitly declare mason.nvim as a dependency for mason-lspconfig.nvim
            { "mason-org/mason.nvim", opts = {} },
            -- Explicitly declare nvim-lspconfig as a dependency
            "neovim/nvim-lspconfig",
        },
    },

    -- DAP Support (Mason-based)
    {
        "jay-babu/mason-nvim-dap.nvim",
        opts = { -- Use opts for setup
            ensure_installed = { "java-debug-adapter", "java-test" }
        }
    },

    -- Java LSP (JDTLS) - This plugin does not typically have a .setup() call on its own,
    -- but rather is configured via nvim-lspconfig.
    {
        "mfussenegger/nvim-jdtls",
        dependencies = {
            "mfussenegger/nvim-dap", -- Assuming this is needed for JDTLS's DAP integration
        },
    },

    -- LSP Setup (nvim-lspconfig)
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

            -- Clangd setup (uncommented and consolidated for direct lspconfig setup)
            lspconfig.clangd.setup({
                cmd = { "clangd" }, -- This uses your globally installed clangd (or one installed by Mason if you add "clangd" to ensure_installed)
                filetypes = { "c", "cpp", "objc", "objcpp" },
                root_dir = lspconfig.util.root_pattern("compile_commands.json", "compile_flags.txt", ".git"),
            })

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

            -- Angular LSP (Local ngserver)
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
                on_new_config = function(new_config)
                    new_config.cmd_env = {
                        PATH = "/usr/bin:" .. os.getenv("PATH"),
                    }
                end,
                settings = {
                    angular = {
                        strictTemplates = true,
                    }
                },
            })

            -- ✅ ESLint via LSP (no more eslint_d / null-ls)
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

