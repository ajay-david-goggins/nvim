-- 🧠 React LSP setup (TypeScript, JavaScript, JSX, TSX)
-- File: lua/plugins/lsp-react.lua

return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
            "jose-elias-alvarez/null-ls.nvim", -- you can keep none-ls or null-ls
        },
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            local util = require("lspconfig.util")

            -- ✅ TypeScript / React LSP config
            local tsserver_config = {
                capabilities = capabilities,
                root_dir = util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
                filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
                settings = {
                    typescript = {
                        inlayHints = {
                            includeInlayParameterNameHints = "all",
                            includeInlayFunctionParameterTypeHints = true,
                            includeInlayVariableTypeHints = true,
                            includeInlayPropertyDeclarationTypeHints = true,
                            includeInlayFunctionLikeReturnTypeHints = true,
                            includeInlayEnumMemberValueHints = true,
                        },
                    },
                    javascript = {
                        inlayHints = {
                            includeInlayParameterNameHints = "all",
                            includeInlayFunctionParameterTypeHints = true,
                            includeInlayVariableTypeHints = true,
                            includeInlayPropertyDeclarationTypeHints = true,
                            includeInlayFunctionLikeReturnTypeHints = true,
                            includeInlayEnumMemberValueHints = true,
                        },
                    },
                },
            }

            -- Start TS / React LSP when opening JS / TS files
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
                callback = function()
                    vim.lsp.start(tsserver_config)
                end,
            })

            -- ✅ ESLint LSP
            local eslint_config = {
                capabilities = capabilities,
                root_dir = util.root_pattern(
                    "eslint.config.mjs",
                    ".eslintrc.js",
                    ".eslintrc.json",
                    ".eslintrc.cjs",
                    "package.json",
                    ".git"
                ),
                on_attach = function(_, bufnr)
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = bufnr,
                        command = "EslintFixAll",
                    })
                end,
            }

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
                callback = function()
                    vim.lsp.start(eslint_config)
                end,
            })

            -- ✅ TailwindCSS
            local tailwind_config = {
                capabilities = capabilities,
                root_dir = util.root_pattern("tailwind.config.js", "postcss.config.js", "package.json", ".git"),
                filetypes = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
            }

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "javascriptreact", "typescriptreact", "html", "vue", "svelte" },
                callback = function()
                    vim.lsp.start(tailwind_config)
                end,
            })

            -- ✅ Emmet LSP
            local emmet_config = {
                capabilities = capabilities,
                filetypes = { "html", "css", "javascriptreact", "typescriptreact", "astro", "vue", "svelte" },
                init_options = { html = { options = { ["bem.enabled"] = true } } },
            }

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "html", "css", "javascriptreact", "typescriptreact", "vue", "svelte" },
                callback = function()
                    vim.lsp.start(emmet_config)
                end,
            })

            -- ✅ Prettier via null-ls
            local null_ls = require("null-ls")
            null_ls.setup({
                sources = {
                    null_ls.builtins.formatting.prettier.with({
                        filetypes = {
                            "javascript", "javascriptreact",
                            "typescript", "typescriptreact",
                            "json", "css", "scss", "html",
                            "markdown",
                        },
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

            -- ✅ Keymaps
            local keymap = vim.keymap.set
            keymap("n", "<leader>ch", vim.lsp.buf.hover, { desc = "[C]ode [H]over", silent = true })
            keymap("n", "<leader>cd", vim.lsp.buf.definition, { desc = "[C]ode [D]efinition", silent = true })
            keymap({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "[C]ode [A]ction", silent = true })
            keymap("n", "<leader>cr", require("telescope.builtin").lsp_references, { desc = "[C]ode [R]eferences", silent = true })
            keymap("n", "<leader>cR", vim.lsp.buf.rename, { desc = "[C]ode [R]ename", silent = true })
            keymap("n", "<leader>cf", function()
                vim.lsp.buf.format({ async = false })
            end, { desc = "[C]ode [F]ormat", silent = true })
        end,
    },
}
