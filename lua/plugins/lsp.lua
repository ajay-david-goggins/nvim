-- =============================================================================
-- plugins/lsp.lua  ·  LSP stack  ·  Mobile-optimized
-- Covers: mason, mason-lspconfig, nvim-lspconfig, nvim-cmp, none-ls, Comment
-- =============================================================================

return {

    -- =========================================================================
    -- 1. MASON  – binary installer
    -- =========================================================================
    {
        "williamboman/mason.nvim",
        lazy = false,
        priority = 100,
        opts = {
            ui = {
                border = "rounded",
                icons  = {
                    package_installed   = "✓",
                    package_pending     = "➜",
                    package_uninstalled = "✗",
                },
            },
        },
    },

    -- =========================================================================
    -- 2. MASON-LSPCONFIG  – auto-install servers
    -- =========================================================================
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            ensure_installed = {
                -- Must-haves
                --"clangd",          -- C / C++
                --"ts_ls",           -- JS / TS
                --"eslint",          -- JS/TS linting
                -- Extras (remove what you don't want)
                -- "lua_ls",          -- Lua (for config editing)
                --"pyright",         -- Python
            },
            automatic_enable = true,
        },
    },

    -- =========================================================================
    -- 3. NVIM-CMP  – lightweight completion
    -- =========================================================================
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",      -- only load on actual insert – saves startup
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
        },
        config = function()
            local cmp     = require("cmp")
            local luasnip = require("luasnip")

            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup({
                snippet = {
                    expand = function(args) luasnip.lsp_expand(args.body) end,
                },
                window = {
                    completion    = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                -- Minimal formatting – no icon table needed (saves memory)
                formatting = {
                    fields = { "abbr", "kind", "menu" },
                    format = function(entry, item)
                        item.menu = ({
                            nvim_lsp = "[LSP]",
                            luasnip  = "[Snip]",
                            buffer   = "[Buf]",
                            path     = "[Path]",
                        })[entry.source.name] or ""
                        return item
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-p>"]     = cmp.mapping.select_prev_item(),
                    ["<C-n>"]     = cmp.mapping.select_next_item(),
                    ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"]     = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"]     = cmp.mapping.abort(),
                    ["<CR>"]      = cmp.mapping.confirm({ select = false }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                -- Fewer sources = faster popup on weak hardware
                sources = cmp.config.sources({
                    { name = "nvim_lsp", priority = 1000 },
                    { name = "luasnip",  priority = 750  },
                    { name = "buffer",   priority = 300, keyword_length = 3 },
                    { name = "path",     priority = 200  },
                }),
                -- Cap menu height – saves render cost on mobile
                view = { entries = { name = "custom", selection_order = "near_cursor" } },
                experimental = { ghost_text = false },   -- off – costly on Termux
            })
        end,
    },

    -- =========================================================================
    -- 4. NONE-LS  – Prettier formatter for JS/TS/HTML/CSS
    -- =========================================================================
    {
        "nvimtools/none-ls.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local null_ls = require("null-ls")
            null_ls.setup({
                sources = {
                    null_ls.builtins.formatting.prettier.with({
                        filetypes = {
                            "html", "css", "scss",
                            "javascript", "javascriptreact",
                            "typescript", "typescriptreact",
                            "json", "jsonc", "markdown",
                        },
                        prefer_local = "node_modules/.bin",
                    }),
                },
            })
        end,
    },

    -- =========================================================================
    -- 5. NVIM-LSPCONFIG  – wires servers + keymaps + diagnostics
    -- =========================================================================
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local servers = require("lsp.servers")
            local utils   = require("lsp.utils")

            -- Apply all server configs
            for name, cfg in pairs(servers) do
                vim.lsp.config(name, cfg)
            end

            -- Rounded borders everywhere
            vim.lsp.config("*", {
                options = { float = { border = "rounded" } },
            })

            -- Diagnostic signs + virtual text
            vim.diagnostic.config({
                virtual_text = { prefix = "●", spacing = 2 },
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = "E",
                        [vim.diagnostic.severity.WARN]  = "W",
                        [vim.diagnostic.severity.HINT]  = "H",
                        [vim.diagnostic.severity.INFO]  = "I",
                    },
                },
                underline        = true,
                update_in_insert = false,   -- no flicker while typing
                severity_sort    = true,
                float = { border = "rounded", source = true },
            })

            -- Single LspAttach autocmd – all keymaps wired here
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client then
                        utils.on_attach(client, args.buf)
                    end
                end,
            })
        end,
    },

    -- =========================================================================
    -- 6. COMMENT.NVIM  – Smart commenting (JS/TS/JSX/TSX aware)
    -- =========================================================================
    {
        "numToStr/Comment.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
        config = function()
            require("ts_context_commentstring").setup({ enable_autocmd = false })

            require("Comment").setup({
                pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
            })

            local api = require("Comment.api")
            vim.keymap.set("n", "<leader>/", api.toggle.linewise.current, { desc = "Comment line" })
            vim.keymap.set("v", "<leader>/",
                "<ESC><CMD>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
                { desc = "Comment selection" }
            )
        end,
    },
}
