-- 🧠 React LSP setup (TypeScript, JavaScript, JSX, TSX)
-- File: lua/plugins/lsp-react.lua

return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
            "jose-elias-alvarez/null-ls.nvim", -- for prettier / eslint formatting
        },
        config = function()
            local lspconfig = require("lspconfig")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            local util = require("lspconfig.util")

            -- ✅ TypeScript & React (JSX / TSX)
            lspconfig.ts_ls.setup({
                capabilities = capabilities,
                root_dir = util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
                filetypes = {
                    "javascript", "javascriptreact",
                    "typescript", "typescriptreact",
                },
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
            })

            -- ✅ ESLint for React projects
            lspconfig.eslint.setup({
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
                    -- Auto-fix before save
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = bufnr,
                        command = "EslintFixAll",
                    })
                end,
            })

            -- ✅ Tailwind CSS - class suggestions in JSX/TSX
            lspconfig.tailwindcss.setup({
                capabilities = capabilities,
                root_dir = util.root_pattern("tailwind.config.js", "postcss.config.js", "package.json", ".git"),
                filetypes = {
                    "html", "css", "javascript", "javascriptreact",
                    "typescript", "typescriptreact", "vue", "svelte",
                },
            })

            -- ✅ Emmet for JSX / TSX
            lspconfig.emmet_ls.setup({
                capabilities = capabilities,
                filetypes = {
                    "html", "css", "javascriptreact", "typescriptreact",
                    "astro", "vue", "svelte",
                },
                init_options = {
                    html = { options = { ["bem.enabled"] = true } },
                },
            })

            -- ✅ Prettier formatting using null-ls
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
                        vim.api.nvim_clear_autocmds({ group = "LspFormatting", buffer = bufnr })
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
                            buffer = bufnr,
                            callback = function()
                                vim.lsp.buf.format({ async = false })
                            end,
                        })
                    end
                end,
            })

            -- ✅ Keybindings (React focused)
            local opts = { noremap = true, silent = true }
            vim.keymap.set("n", "<leader>ch", vim.lsp.buf.hover, { desc = "[C]ode [H]over" })
            vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition, { desc = "[C]ode [D]efinition" })
            vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "[C]ode [A]ction" })
            vim.keymap.set("n", "<leader>cr", require("telescope.builtin").lsp_references, { desc = "[C]ode [R]eferences" })
            vim.keymap.set("n", "<leader>cR", vim.lsp.buf.rename, { desc = "[C]ode [R]ename" })
            vim.keymap.set("n", "<leader>cf", vim.lsp.buf.format, { desc = "[C]ode [F]ormat" })
        end,
    },
}
