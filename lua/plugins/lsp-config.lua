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
                    "ts_ls",
                    "html",
                    "cssls",
                    "emmet_ls",
                    "eslint",
                    "clangd",
                    "jdtls",
                    "tailwindcss",
                    "angularls",
                },
            })
        end,
    },

    -- Mason DAP Installer
    {
        "jay-babu/mason-nvim-dap.nvim",
        config = function()
            require("mason-nvim-dap").setup({
                ensure_installed = { "java-debug-adapter", "java-test" },
            })
        end,
    },

    -- Java LSP (JDTLS)
    {
        "mfussenegger/nvim-jdtls",
        dependencies = { "mfussenegger/nvim-dap" },
    },

    -- LSP Config
    {
        "neovim/nvim-lspconfig",
        dependencies = { "hrsh7th/cmp-nvim-lsp", "jose-elias-alvarez/null-ls.nvim" },
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            local util = require("lspconfig.util")
            local lspconfig = require("lspconfig")

            -- Helper to start LSP with new API
            local function start_lsp(server_config, filetypes)
                vim.api.nvim_create_autocmd("FileType", {
                    pattern = filetypes,
                    callback = function()
                        vim.lsp.start(server_config)
                    end,
                })
            end

            -- ✅ Lua LSP
            start_lsp({ name = "lua_ls", capabilities = capabilities }, { "lua" })

            -- ✅ TypeScript / React LSP
            start_lsp({
                name = "ts_ls",
                capabilities = capabilities,
                root_dir = util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
                filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
            }, { "javascript", "javascriptreact", "typescript", "typescriptreact" })

            -- ✅ HTML / CSS LSPs
            start_lsp({ name = "html", capabilities = capabilities }, { "html" })
            start_lsp({ name = "cssls", capabilities = capabilities }, { "css" })

            -- ✅ Clangd
            start_lsp({ name = "clangd", capabilities = capabilities }, { "c", "cpp" })

            -- ✅ TailwindCSS
            start_lsp({
                name = "tailwindcss",
                capabilities = capabilities,
                root_dir = util.root_pattern("tailwind.config.js", "postcss.config.js", "package.json", ".git"),
                filetypes = { "html", "javascript", "javascriptreact", "typescript", "typescriptreact", "php", "blade", "vue", "svelte" },
            }, { "html", "javascriptreact", "typescriptreact", "vue", "svelte" })

            -- ✅ Emmet
            start_lsp({
                name = "emmet_ls",
                capabilities = capabilities,
                filetypes = { "html", "css", "php", "blade", "javascriptreact", "typescriptreact", "astro", "vue", "svelte" },
                init_options = { html = { options = { ["bem.enabled"] = true } } },
            }, { "html", "css", "javascriptreact", "typescriptreact", "vue", "svelte" })

            -- ✅ Angular LSP
            start_lsp({
                name = "angularls",
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
            }, { "typescript", "html", "scss", "css" })

            -- ✅ ESLint
            start_lsp({
                name = "eslint",
                capabilities = capabilities,
                root_dir = util.root_pattern("eslint.config.mjs", ".eslintrc.js", ".eslintrc.json", ".eslintrc.cjs", "package.json", ".git"),
                on_attach = function(_, bufnr)
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = bufnr,
                        command = "EslintFixAll",
                    })
                end,
            }, { "javascript", "javascriptreact", "typescript", "typescriptreact" })

            -- ✅ Null-ls Prettier formatting
            local null_ls = require("null-ls")
            null_ls.setup({
                sources = {
                    null_ls.builtins.formatting.prettier.with({
                        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "css", "scss", "html", "markdown" },
                    }),
                },
                on_attach = function(client, bufnr)
                    if client.supports_method("textDocument/formatting") then
                        local group = vim.api.nvim_create_augroup("LspFormatting", { clear = true })
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            group = group,
                            buffer = bufnr,
                            callback = function()
                                vim.lsp.buf.format({ async = false })
                            end,
                        })
                    end
                end,
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
