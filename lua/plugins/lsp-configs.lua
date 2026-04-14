-- =============================================================================
-- lsp-configs.lua  ·  Neovim 0.13+ · Arch Linux · 2026
-- Modern, lightweight, IDE-grade LSP setup
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
                icons = {
                    package_installed   = "󰄬 ",
                    package_pending     = "󰔟 ",
                    package_uninstalled = "󰅖 ",
                },
            },
        },
    },

    -- =========================================================================
    -- 2. MASON-LSPCONFIG  – auto-installs + bridges mason → vim.lsp
    -- =========================================================================
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            ensure_installed = {
                "lua_ls", "ts_ls", "html", "cssls",
                "emmet_ls", "eslint", "clangd",
                "tailwindcss", "angularls",
            },
            automatic_enable = true,
        },
    },

    -- =========================================================================
    -- 3. NVIM-DAP  – debug core (must load BEFORE mason-nvim-dap)
    -- =========================================================================
    {
        "mfussenegger/nvim-dap",
        lazy = true,
    },

    -- =========================================================================
    -- 4. MASON-DAP  – debug adapter installer
    -- =========================================================================
    {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = {
            "williamboman/mason.nvim",
            "mfussenegger/nvim-dap",
        },
        opts = {
            ensure_installed       = { "java-debug-adapter", "java-test" },
            automatic_installation = true,
            handlers               = {},
        },
    },

    -- =========================================================================
    -- 5. NVIM-CMP  – completion engine (was missing → caused "cmp not found")
    -- =========================================================================
    {
        "hrsh7th/nvim-cmp",
        event = { "InsertEnter", "CmdlineEnter" },
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
        },
        config = function()
            local cmp     = require("cmp")
            local luasnip = require("luasnip")

            require("luasnip.loaders.from_vscode").lazy_load()

            local kind_icons = {
                Text          = "󰉿 ",
                Method        = "󰆧 ",
                Function      = "󰊕 ",
                Constructor   = "C ",
                Field         = "󰜢 ",
                Variable      = "󰀫 ",
                Class         = "󰠱 ",
                Interface     = "I ",
                Module        = "M ",
                Property      = "󰜢 ",
                Unit          = "󰑭 ",
                Value         = "󰎠 ",
                Enum          = "E ",
                Keyword       = "󰌋 ",
                Snippet       = "S ",
                Color         = "󰏘 ",
                File          = "󰈙 ",
                Reference     = "󰈇 ",
                Folder        = "󰉋 ",
                EnumMember    = "EM ",
                Constant      = "󰏿 ",
                Struct        = "󰙅 ",
                Event         = "EV ",
                Operator      = "󰆕 ",
                TypeParameter = "TP ",
            }

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                window = {
                    completion    = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                formatting = {
                    fields = { "kind", "abbr", "menu" },
                    format = function(entry, item)
                        item.kind = (kind_icons[item.kind] or " ") .. item.kind
                        item.menu = ({
                            nvim_lsp = "[LSP]",
                            luasnip  = "[Snip]",
                            buffer   = "[Buf]",
                            path     = "[Path]",
                        })[entry.source.name] or "[?]"
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
                    ["<Cr>"]      = cmp.mapping.confirm({ select = false }),
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
                sources = cmp.config.sources({
                    { name = "nvim_lsp", priority = 1000 },
                    { name = "luasnip",  priority = 750  },
                    { name = "buffer",   priority = 500  },
                    { name = "path",     priority = 250  },
                }),
            })

            cmp.setup.cmdline({ "/", "?" }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = { { name = "buffer" } },
            })
            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources(
                    { { name = "path" } },
                    { { name = "cmdline" } }
                ),
            })
        end,
    },

    -- =========================================================================
    -- 6. NONE-LS  – Prettier formatting
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
                            "json", "jsonc", "markdown","java",
                        },
                        prefer_local = "node_modules/.bin",
                    }),
                },
            })
        end,
    },

    -- =========================================================================
    -- 7. NVIM-JDTLS  – Java LSP + DAP
    -- =========================================================================
    {
        "mfussenegger/nvim-jdtls",
        dependencies = { "mfussenegger/nvim-dap" },
        ft = { "java" },
        config = function()
            local home      = os.getenv("HOME")
            local mason_pkg = home .. "/.local/share/nvim/mason/packages"
            local data_dir  = home .. "/.local/share/nvim/jdtls"
            local project   = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
            local workspace = data_dir .. "/workspace/" .. project

            local bundles = {}
            local debug_jar = vim.fn.glob(
                mason_pkg .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
            )
            if debug_jar ~= "" then vim.list_extend(bundles, { debug_jar }) end
            vim.list_extend(bundles, vim.split(
                vim.fn.glob(mason_pkg .. "/java-test/extension/server/*.jar"),
                "\n", { trimempty = true }
            ))

            require("jdtls").start_or_attach({
                cmd = {
                    "java",
                    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
                    "-Dosgi.bundles.defaultStartLevel=4",
                    "-Declipse.product=org.eclipse.jdt.ls.core.product",
                    "-Dlog.level=ALL", "-Xmx2g",
                    "--add-modules=ALL-SYSTEM",
                    "--add-opens", "java.base/java.util=ALL-UNNAMED",
                    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
                    "-jar", vim.fn.glob(mason_pkg .. "/jdtls/plugins/org.eclipse.equinox.launcher_*.jar"),
                    "-configuration", mason_pkg .. "/jdtls/config_linux",
                    "-data", workspace,
                },
                root_dir = require("jdtls.setup").find_root({
                    "gradlew", "mvnw", ".git", "pom.xml", "build.gradle",
                }),
                settings = {
                    java = {
                        eclipse       = { downloadSources = true },
                        maven         = { downloadSources = true },
                        inlayHints    = { parameterNames = { enabled = "all" } },
                        signatureHelp = { enabled = true },
                        referencesCodeLens      = { enabled = true },
                        implementationsCodeLens  = { enabled = true },
                    },
                },
                init_options = {
                    bundles = bundles,
                    extendedClientCapabilities = require("jdtls").extendedClientCapabilities,
                },
                on_attach = function(_, bufnr)
                    require("jdtls").setup_dap({ hotcodereplace = "auto" })
                    require("jdtls.dap").setup_dap_main_class_configs()
                    local o = { buffer = bufnr, silent = true }
                    local jdtls = require("jdtls")
                    vim.keymap.set("n", "<leader>jo", jdtls.organize_imports,  vim.tbl_extend("force", o, { desc = "󰶮  Java Organize Imports" }))
                    vim.keymap.set("n", "<leader>jv", jdtls.extract_variable,  vim.tbl_extend("force", o, { desc = "󰫙  Java Extract Variable"  }))
                    vim.keymap.set("n", "<leader>jc", jdtls.extract_constant,  vim.tbl_extend("force", o, { desc = "󰏿  Java Extract Constant"  }))
                    vim.keymap.set("v", "<leader>jm", [[<ESC><CMD>lua require("jdtls").extract_method(true)<CR>]], vim.tbl_extend("force", o, { desc = "󰊕  Java Extract Method" }))
                    vim.keymap.set("n", "<leader>dt", jdtls.test_nearest_method, vim.tbl_extend("force", o, { desc = "󰙨  DAP Test Method" }))
                    vim.keymap.set("n", "<leader>dT", jdtls.test_class,          vim.tbl_extend("force", o, { desc = "󰙨  DAP Test Class"   }))
                end,
            })
        end,
    },

    -- =========================================================================
    -- 8. NVIM-LSPCONFIG  – server settings + keymaps + autocommands
    -- =========================================================================
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
            "nvimtools/none-ls.nvim",
        },
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- ------------------------------------------------------------------
            -- Per-server settings via 0.11+ vim.lsp.config API
            -- ------------------------------------------------------------------
            local servers = {
                lua_ls = {
                    capabilities = capabilities,
                    settings = {
                        Lua = {
                            runtime     = { version = "LuaJIT" },
                            diagnostics = { globals = { "vim" } },
                            workspace   = {
                                library = { vim.env.VIMRUNTIME },
                                checkThirdParty = false,
                            },
                            telemetry = { enable = false },
                            hint      = { enable = true, semicolon = "Disable" },
                            codeLens  = { enable = true },
                        },
                    },
                },

                ts_ls = {
                    capabilities = capabilities,
                    settings = {
                        typescript = {
                            inlayHints = {
                                includeInlayParameterNameHints           = "all",
                                includeInlayFunctionParameterTypeHints   = true,
                                includeInlayVariableTypeHints            = true,
                                includeInlayPropertyDeclarationTypeHints = true,
                                includeInlayFunctionLikeReturnTypeHints  = true,
                                includeInlayEnumMemberValueHints         = true,
                            },
                        },
                        javascript = {
                            inlayHints = {
                                includeInlayParameterNameHints           = "all",
                                includeInlayFunctionParameterTypeHints   = true,
                                includeInlayVariableTypeHints            = true,
                                includeInlayPropertyDeclarationTypeHints = true,
                                includeInlayFunctionLikeReturnTypeHints  = true,
                                includeInlayEnumMemberValueHints         = true,
                            },
                        },
                    },
                },

                html        = { capabilities = capabilities },
                cssls       = { capabilities = capabilities },
                angularls   = { capabilities = capabilities },
                tailwindcss = { capabilities = capabilities },

                clangd = {
                    capabilities = capabilities,
                    cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
                },

                emmet_ls = {
                    capabilities = capabilities,
                    init_options = {
                        html = { options = { ["bem.enabled"] = true } },
                    },
                },

                eslint = {
                    capabilities = capabilities,
                    settings = {
                        codeActionOnSave = { enable = true, mode = "all" },
                    },
                },
            }

            for server, cfg in pairs(servers) do
                vim.lsp.config(server, cfg)
            end

            -- ------------------------------------------------------------------
            -- Rounded borders for hover + signature help (0.13 way, no vim.lsp.with)
            -- ------------------------------------------------------------------
            --vim.lsp.config("*", {
            --    handlers = {
            --        ["textDocument/hover"] = function(err, result, ctx, config)
            --            config = vim.tbl_extend("force", config or {}, { border = "rounded" })
            --            vim.lsp.handlers.hover(err, result, ctx, config)
            --        end,
            --        ["textDocument/signatureHelp"] = function(err, result, ctx, config)
            --            config = vim.tbl_extend("force", config or {}, { border = "rounded" })
            --            vim.lsp.handlers.signature_help(err, result, ctx, config)
            --        end,
            --    },
            --})

            -- ------------------------------------------------------------------
            -- Modern 0.13 way for Global UI settings
            -- ------------------------------------------------------------------
            vim.lsp.config("*", {
                -- Instead of overriding the handler function, 
                -- we pass options directly to the default handlers.
                options = {
                    float = {
                        border = "rounded",
                    },
                },
            })

            -- ------------------------------------------------------------------
            -- Diagnostic config with Nerd Font icons
            -- ------------------------------------------------------------------
            vim.diagnostic.config({
                virtual_text = {
                    prefix  = "●",
                    spacing = 4,
                },
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = " ",
                        [vim.diagnostic.severity.WARN]  = " ",
                        [vim.diagnostic.severity.HINT]  = "󰠠 ",
                        [vim.diagnostic.severity.INFO]  = " ",
                    },
                },
                underline        = true,
                update_in_insert = false,
                severity_sort    = true,
                float = {
                    border = "rounded",
                    source = true,
                    header = "",
                    prefix = "",
                },
            })

            -- ------------------------------------------------------------------
            -- LspAttach: keymaps + per-client behaviour
            -- <leader>e is intentionally left FREE for nvim-tree
            -- ------------------------------------------------------------------
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
                callback = function(args)
                    local buf    = args.buf
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if not client then return end

                    local map = function(mode, lhs, rhs, desc)
                        vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
                    end

                    -- Navigation
                    map("n",        "<leader>ch", vim.lsp.buf.hover,           "󰋖  [C]ode [H]over Docs")
                    map("n",        "<leader>cd", vim.lsp.buf.definition,      "󰈮  Go to [C]ode [D]efinition")
                    map("n",        "<leader>cD", vim.lsp.buf.declaration,     "󰈮  Go to [C]ode [[D]]eclaration")
                    map("n",        "<leader>ci", vim.lsp.buf.implementation,  "󰡱  Go to [C]ode [I]mplementation")
                    map("n",        "<leader>ct", vim.lsp.buf.type_definition, "󰆧  Go to [C]ode [T]ype Def")
                    map("n",        "<leader>cr", function()
                        require("telescope.builtin").lsp_references()
                    end, "󰈇  go to [C]ode [R]eferences")
                    map("n",        "<leader>cI", function()
                        require("telescope.builtin").lsp_implementations()
                    end, "󰡱  go to [C]ode [I]mplementations")

                    -- Refactor
                    map("n",        "<leader>cR", vim.lsp.buf.rename,          "󰏫  Rename Symbol")
                    map({ "n","v"}, "<leader>ca", vim.lsp.buf.code_action,     "󰌶  Code Action")

                    -- Diagnostics  (use <leader>E — uppercase — to leave <leader>e for nvim-tree)
                    map("n", "<leader>do",  vim.diagnostic.open_float,          "󰅚  [D]iagnostic Float")
                    map("n", "<leader>dp",         vim.diagnostic.goto_prev,           "󰮳  Prev Diagnostic")
                    map("n", "<leader>dn",         vim.diagnostic.goto_next,           "󰮴  Next Diagnostic")
                    map("n", "<leader>dq",  vim.diagnostic.setloclist,          "󰅙  Diagnostic Quickfix")

                    -- Format
                    --map("n", "<leader>cf", function()
                    --    vim.lsp.buf.format({ async = false, bufnr = buf })
                    --end, "󰉿  Format Buffer")

                    -- Toggle inlay hints
                    map("n", "<leader>cH", function()
                        vim.lsp.inlay_hint.enable(
                            not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }),
                            { bufnr = buf }
                        )
                    end, "󰊈  Toggle Inlay [C]ode [[H]]ints")

                    -- ESLint auto-fix on save
                    if client.name == "eslint" then
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            buffer  = buf,
                            command = "EslintFixAll",
                        })
                    end

                    -- Prettier format on save (null-ls only, colon API for 0.13)
                    if client.name == "null-ls" and client:supports_method("textDocument/formatting") then
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            group = vim.api.nvim_create_augroup("NullLsFmt_" .. buf, { clear = true }),
                            buffer = buf,
                            callback = function()
                                vim.lsp.buf.format({
                                    bufnr  = buf,
                                    async  = false,
                                    filter = function(c) return c.name == "null-ls" end,
                                })
                            end,
                        })
                    end
                end,
            })
        end,
    },
}
