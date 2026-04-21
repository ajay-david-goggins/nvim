-- =============================================================================
-- python.lua  ·  Neovim 0.13+ · Arch Linux · 2026
-- Python LSP (pyright) + Ruff lint/format + debugpy DAP
-- =============================================================================

return {

    -- =========================================================================
    -- 1. MASON-LSPCONFIG  – add pyright + ruff to ensure_installed
    -- =========================================================================
    {
        "williamboman/mason-lspconfig.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, {
                "pyright",
                "ruff",
            })
        end,
    },

    -- =========================================================================
    -- 2. MASON-DAP  – add debugpy
    -- =========================================================================
    {
        "jay-babu/mason-nvim-dap.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "debugpy" })
        end,
    },

    -- =========================================================================
    -- 3. CONFORM  – ruff format on save
    -- =========================================================================
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        opts = {
            formatters_by_ft = {
                python = { "ruff_format", "ruff_organize_imports" },
            },
            format_on_save = {
                timeout_ms   = 2000,
                lsp_fallback = false,
            },
        },
    },

    -- =========================================================================
    -- 4. NVIM-LINT  – ruff diagnostics
    -- =========================================================================
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = { python = { "ruff" } }
            vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
                callback = function()
                    lint.try_lint()
                end,
            })
        end,
    },

    -- =========================================================================
    -- 5. NVIM-LSPCONFIG  – pyright + ruff LSP settings
    -- =========================================================================
    {
        "neovim/nvim-lspconfig",
        opts = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- ── Pyright ──────────────────────────────────────────────────────
            vim.lsp.config("pyright", {
                capabilities = capabilities,
                settings = {
                    python = {
                        analysis = {
                            typeCheckingMode       = "basic",   -- "off" | "basic" | "strict"
                            autoSearchPaths        = true,
                            useLibraryCodeForTypes = true,
                            diagnosticMode         = "workspace",

                            -- Suppress / downgrade specific pyright rules:
                            -- "none" = silence, "warning" = downgrade, "error" = upgrade
                            diagnosticSeverityOverrides = {
                                reportMissingImports        = "none",
                                reportMissingTypeStubs      = "none",
                                reportUnusedImport          = "warning",
                                reportUnusedVariable        = "warning",
                                reportPrivateUsage          = "none",
                                reportAttributeAccessIssue  = "warning",
                                -- reportGeneralTypeIssues  = "none",
                                -- reportReturnType         = "none",
                            },
                        },
                    },
                },
            })

            -- ── Ruff LSP (code actions only, hover disabled → pyright handles it)
            vim.lsp.config("ruff", {
                capabilities = capabilities,
                on_attach = function(client, _)
                    client.server_capabilities.hoverProvider = false
                end,
                init_options = {
                    settings = {
                        lint = {
                            -- Ignore specific ruff rule codes:
                            ignore = {
                                "E501",  -- line too long (formatter handles it)
                                "F401",  -- imported but unused (intentional sometimes)
                                -- "E302",
                                -- "ANN",
                            },
                        },
                    },
                },
            })
        end,
    },

    -- =========================================================================
    -- 6. NVIM-DAP  – debugpy adapter + configurations + keymaps
    -- =========================================================================
    {
        "mfussenegger/nvim-dap",
        ft = { "python" },
        config = function()
            local dap     = require("dap")
            local mason_pkg = vim.fn.expand("~/.local/share/nvim/mason/packages")

            -- ── Adapter ──────────────────────────────────────────────────────
            dap.adapters.python = {
                type    = "executable",
                command = mason_pkg .. "/debugpy/venv/bin/python",
                args    = { "-m", "debugpy.adapter" },
            }

            -- ── Helper: prefer .venv, fall back to system python ─────────────
            local function get_python()
                local venv = vim.fn.getcwd() .. "/.venv/bin/python"
                if vim.fn.executable(venv) == 1 then return venv end
                return vim.fn.exepath("python3") or "python"
            end

            -- ── Debug configurations ──────────────────────────────────────────
            dap.configurations.python = {
                {
                    type       = "python",
                    request    = "launch",
                    name       = "Launch file",
                    program    = "${file}",
                    pythonPath = get_python,
                },
                {
                    type       = "python",
                    request    = "launch",
                    name       = "Launch with args",
                    program    = "${file}",
                    args       = function()
                        local args = vim.fn.input("Args: ")
                        return vim.split(args, " ", { trimempty = true })
                    end,
                    pythonPath = get_python,
                },
                {
                    type       = "python",
                    request    = "launch",
                    name       = "pytest: current file",
                    module     = "pytest",
                    args       = { "${file}", "-v" },
                    pythonPath = get_python,
                },
            }

            -- ── Keymaps (python buffers only) ─────────────────────────────────
            vim.api.nvim_create_autocmd("FileType", {
                pattern  = "python",
                callback = function(args)
                    local buf = args.buf
                    local o   = { buffer = buf, silent = true }
                    local map = function(lhs, rhs, desc)
                        vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", o, { desc = desc }))
                    end

                    map("<leader>db", dap.toggle_breakpoint,  "  Toggle Breakpoint")
                    map("<leader>dc", dap.continue,           "  DAP Continue")
                    map("<leader>di", dap.step_into,          "  DAP Step Into")
                    map("<leader>do", dap.step_over,          "  DAP Step Over")
                    map("<leader>dO", dap.step_out,           "  DAP Step Out")
                    map("<leader>dr", dap.repl.open,          "  DAP REPL")
                    map("<leader>dl", dap.run_last,           "  DAP Run Last")
                end,
            })
        end,
    },
}
