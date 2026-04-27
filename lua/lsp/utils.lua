-- =============================================================================
-- lsp/utils.lua  ·  Shared LSP helpers (no plugin deps here)
-- =============================================================================
local M = {}

--- Build cmp capabilities once and reuse
function M.capabilities()
    local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok then
        return cmp_lsp.default_capabilities()
    end
    return vim.lsp.protocol.make_client_capabilities()
end

--- Attach keymaps on LspAttach – called from the autocmd in lsp.lua
---@param buf integer
---@param client vim.lsp.Client
function M.on_attach(client, buf)
    local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
    end

    -- Navigation
    map("n", "<leader>ch", vim.lsp.buf.hover,           "Code hover docs")
    map("n", "<leader>cd", vim.lsp.buf.definition,      "Go to definition")
    map("n", "<leader>cD", vim.lsp.buf.declaration,     "Go to declaration")
    map("n", "<leader>ci", vim.lsp.buf.implementation,  "Go to implementation")
    map("n", "<leader>ct", vim.lsp.buf.type_definition, "Go to type def")
    map("n", "<leader>cr", vim.lsp.buf.references,      "References")

    -- Refactor
    map("n",        "<leader>cR", vim.lsp.buf.rename,      "Rename symbol")
    map({ "n","v"}, "<leader>ca", vim.lsp.buf.code_action, "Code action")

    -- Diagnostics
    map("n", "<leader>do", vim.diagnostic.open_float,  "Diagnostic float")
    map("n", "<leader>dp", vim.diagnostic.goto_prev,   "Prev diagnostic")
    map("n", "<leader>dn", vim.diagnostic.goto_next,   "Next diagnostic")
    map("n", "<leader>dq", vim.diagnostic.setloclist,  "Diagnostic list")

    -- Inlay hints toggle (Neovim 0.10+)
    if vim.lsp.inlay_hint then
        map("n", "<leader>cH", function()
            vim.lsp.inlay_hint.enable(
                not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }),
                { bufnr = buf }
            )
        end, "Toggle inlay hints")
    end

    -- Prettier / conform format on save – null-ls client
    if client.name == "null-ls" and client:supports_method("textDocument/formatting") then
        vim.api.nvim_create_autocmd("BufWritePre", {
            group  = vim.api.nvim_create_augroup("NullLsFmt_" .. buf, { clear = true }),
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

    -- ESLint: auto-fix all on save
    if client.name == "eslint" then
        vim.api.nvim_create_autocmd("BufWritePre", {
            buffer  = buf,
            command = "EslintFixAll",
        })
    end
end

return M
