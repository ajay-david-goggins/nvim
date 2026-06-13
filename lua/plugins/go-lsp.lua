-- =============================================================================
-- go-lsp.lua  ·  Neovim 0.13+ · Arch Linux · 2026
-- Go LSP setup — mirrors the same patterns as your lsp-configs.lua
-- =============================================================================

return {

    -- =========================================================================
    -- 1. MASON: ensure Go tools are installed
    --    gopls          – official Go language server
    --    goimports      – goimports binary (used by none-ls)
    --    delve          – Go debugger (DAP backend)
    --    gomodifytags   – add/remove struct tags
    --    impl           – generate interface stubs
    -- =========================================================================
    {
        "williamboman/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, {
                "gopls",
                "goimports",
                "delve",
                "gomodifytags",
                "impl",
            })
        end,
    },

    -- =========================================================================
    -- 2. MASON-LSPCONFIG: register gopls for automatic enable
    -- =========================================================================
    {
        "williamboman/mason-lspconfig.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "gopls" })
        end,
    },

    -- =========================================================================
    -- 3. MASON-DAP: install the delve debug adapter
    -- =========================================================================
    {
        "jay-babu/mason-nvim-dap.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "delve" })
        end,
    },

    -- =========================================================================
    -- 4. NVIM-DAP-GO  – thin wrapper that wires delve into nvim-dap
    --    Provides :DapContinue, test-function runner, etc.
    -- =========================================================================
    {
        "leoluz/nvim-dap-go",
        ft = "go",
        dependencies = { "mfussenegger/nvim-dap" },
        opts = {
            -- delve binary path (mason puts it here)
            dap_configurations = {
                {
                    type  = "go",
                    name  = "Debug",
                    request = "launch",
                    program = "${file}",
                },
                {
                    type  = "go",
                    name  = "Debug Package",
                    request = "launch",
                    program = "${fileDirname}",
                },
                {
                    type  = "go",
                    name  = "Attach (remote)",
                    request = "attach",
                    mode    = "remote",
                    remotePath = "${workspaceFolder}",
                },
            },
            delve = {
                -- mason installs here; change if you have a system delve
                path = vim.fn.exepath("dlv"),
                initialize_timeout_sec = 20,
                port = "${port}",
                args = {},
                build_flags = "",
            },
        },
    },

    -- =========================================================================
    -- 5. NONE-LS: goimports formatter (replaces gofmt + manages imports)
    --    Appended to your existing none-ls sources — does NOT replace them.
    -- =========================================================================
    {
        "nvimtools/none-ls.nvim",
        opts = function(_, opts)
            local null_ls = require("null-ls")
            opts.sources = opts.sources or {}
            vim.list_extend(opts.sources, {
                -- goimports: formats AND organises imports in one shot
                null_ls.builtins.formatting.goimports.with({
                    extra_args = { "-local", "" }, -- set your module prefix if needed
                }),
                -- gofumpt: stricter gofmt (optional; remove if you only want goimports)
                null_ls.builtins.formatting.gofumpt,
            })
        end,
    },

    -- =========================================================================
    -- 6. NVIM-LSPCONFIG: gopls server config via 0.13 vim.lsp.config API
    -- =========================================================================
    {
        "neovim/nvim-lspconfig",
        -- ft guard is NOT set here so the global LspAttach autocmd still fires
        config = function(_, _)
            -- grab base config set up by your existing lsp-configs.lua
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- ----------------------------------------------------------------
            -- gopls settings
            -- Full reference: https://github.com/golang/tools/blob/master/gopls/doc/settings.md
            -- ----------------------------------------------------------------
            vim.lsp.config("gopls", {
                capabilities = capabilities,
                settings = {
                    gopls = {
                        -- Analysis / linters
                        analyses = {
                            unusedparams  = true,
                            unusedvariable = true,
                            shadow        = true,
                            nilness       = true,
                            useany        = true,
                        },
                        staticcheck = true,   -- runs staticcheck via gopls

                        -- Formatting (gofumpt is stricter gofmt)
                        gofumpt = true,

                        -- Inlay hints (matches your ts_ls style)
                        hints = {
                            assignVariableTypes    = true,
                            compositeLiteralFields = true,
                            compositeLiteralTypes  = true,
                            constantValues         = true,
                            functionTypeParameters = true,
                            parameterNames         = true,
                            rangeVariableTypes     = true,
                        },

                        -- Code lenses (show "run" / "test" above funcs)
                        codelenses = {
                            gc_details      = true,  -- show GC pressure
                            generate        = true,  -- go generate
                            run_govulncheck = true,
                            test            = true,
                            tidy            = true,
                            upgrade_dependency = true,
                            vendor          = true,
                        },

                        -- Completion
                        usePlaceholders    = true,   -- fill func params on complete
                        completeUnimported = true,   -- auto-import on complete
                        matcher            = "Fuzzy",

                        -- Semantic tokens (richer highlighting)
                        semanticTokens = true,

                        -- Build tags (add yours if needed)
                        buildFlags = {},

                        directoryFilters = {
                            "-.git", "-.vscode", "-.idea",
                            "-node_modules", "-vendor",
                        },
                    },
                },
            })

            -- ----------------------------------------------------------------
            -- Go-specific LspAttach keymaps + format-on-save
            -- ----------------------------------------------------------------
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("GoLspAttach", { clear = true }),
                pattern = "*.go",
                callback = function(args)
                    local buf    = args.buf
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if not client then return end

                    local map = function(mode, lhs, rhs, desc)
                        vim.keymap.set(mode, lhs, rhs,
                            { buffer = buf, silent = true, desc = desc })
                    end

                    -- Go-specific refactor actions via gopls
                    map("n", "<leader>go", function()
                        -- Organize imports via gopls code action
                        vim.lsp.buf.code_action({
                            context = { only = { "source.organizeImports" } },
                            apply   = true,
                        })
                    end, "󰶮  Go Organize Imports")

                    map("n", "<leader>gf", function()
                        -- Fill struct (gopls: fill_struct code action)
                        vim.lsp.buf.code_action({
                            context = { only = { "refactor.rewrite" } },
                        })
                    end, "󰙅  Go Fill Struct")

                    map("n", "<leader>gt", function()
                        -- gomodifytags (runs as external cmd, not LSP)
                        -- Usage: cursor on struct field or struct line
                        local tag = vim.fn.input("Tag (e.g. json): ")
                        if tag == "" then return end
                        local file = vim.fn.expand("%")
                        local line = vim.fn.line(".")
                        local cmd  = string.format(
                            "gomodifytags -file %s -line %d -add-tags %s -transform camelcase",
                            file, line, tag
                        )
                        local result = vim.fn.system(cmd)
                        if vim.v.shell_error == 0 then
                            -- reload buffer with new tags
                            vim.cmd("edit!")
                        else
                            vim.notify("gomodifytags error:\n" .. result, vim.log.levels.ERROR)
                        end
                    end, "󰓼  Go Modify Tags")

                    map("n", "<leader>gi", function()
                        -- impl: generate interface stub
                        local recv  = vim.fn.input("Receiver (e.g. r *MyType): ")
                        local iface = vim.fn.input("Interface (e.g. io.Reader): ")
                        if recv == "" or iface == "" then return end
                        local result = vim.fn.system(
                            string.format("impl '%s' %s", recv, iface)
                        )
                        if vim.v.shell_error == 0 then
                            -- paste at current line
                            local lines = vim.split(result, "\n", { trimempty = true })
                            vim.api.nvim_buf_set_lines(buf, vim.fn.line("."), vim.fn.line("."), false, lines)
                        else
                            vim.notify("impl error:\n" .. result, vim.log.levels.ERROR)
                        end
                    end, "󰡱  Go Implement Interface")

                    -- DAP (dap-go) keymaps — same <leader>d prefix as Java
                    local ok, dap_go = pcall(require, "dap-go")
                    if ok then
                        map("n", "<leader>dt", dap_go.debug_test,         "󰙨  DAP Debug Nearest Test")
                        map("n", "<leader>dT", dap_go.debug_last_test,    "󰙨  DAP Debug Last Test")
                    end

                    local ok2, dap = pcall(require, "dap")
                    if ok2 then
                        map("n", "<leader>dr", dap.continue,              "󰐊  DAP Run/Continue")
                        map("n", "<leader>db", dap.toggle_breakpoint,     "󰴿  DAP Toggle Breakpoint")
                        map("n", "<leader>dso", dap.step_over,            "󰆷  DAP Step Over")
                        map("n", "<leader>dsi", dap.step_into,            "󰆹  DAP Step Into")
                        map("n", "<leader>dq", dap.terminate,             "󰓛  DAP Quit")
                    end

                    -- goimports format on save (none-ls / null-ls)
                    if client.name == "null-ls"
                        and client:supports_method("textDocument/formatting") then
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            group  = vim.api.nvim_create_augroup("GoFmt_" .. buf, { clear = true }),
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

                    -- Toggle inlay hints (same keymap you use for other langs)
                    vim.keymap.set("n", "<leader>cH", function()
                        vim.lsp.inlay_hint.enable(
                            not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }),
                            { bufnr = buf }
                        )
                    end, { buffer = buf, silent = true, desc = "󰊈  Toggle Inlay Hints" })
                end,
            })
        end,
    },
}
