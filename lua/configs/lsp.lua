-- =============================================================================
-- configs/lsp.lua · Neovim 0.13+ · 2026
-- Global LSP wiring: capabilities, enable list, diagnostics UI, keymaps.
-- Per-server settings live one-file-per-server in nvim/lsp/<name>.lua — that
-- directory is auto-merged natively by Neovim (see :h lsp-config), so adding
-- a language server is: add name below + drop a small lsp/<name>.lua file.
-- =============================================================================

local diagnostics = require("configs.diagnostics")

-- Route every publishDiagnostics notification through the session-ignore
-- filter (configs/diagnostics.lua). Without this the filter engine builds
-- its ignore set but nothing ever consults it.
vim.lsp.handlers["textDocument/publishDiagnostics"] = diagnostics.handler

-- Base capabilities, extended with blink.cmp's completion capabilities.
-- Applied to every server via the "*" wildcard config — no repeating this
-- in every lsp/<name>.lua file.
local capabilities = vim.lsp.protocol.make_client_capabilities()
local has_blink, blink = pcall(require, "blink.cmp")
if has_blink then
  capabilities = blink.get_lsp_capabilities(capabilities)
end

vim.lsp.config("*", {
  capabilities = capabilities,
  root_markers = { ".git" },
})

-- Rounded floating windows everywhere (hover, signature help, diagnostics).
vim.lsp.config("*", { options = { float = { border = "rounded" } } })

-- Enable every server; mason-lspconfig (see plugins/mason.lua) installs the
-- underlying binaries. Settings for each come from lsp/<name>.lua.
--
-- Guard each one behind an executable check before calling vim.lsp.enable.
-- This is what actually fixes the recurring "mason not found" spam for Go
-- (gopls/goimports/gomodifytags/impl are NOT mason-managed any more, see
-- plugins/mason.lua for why): if the underlying binary genuinely isn't on
-- PATH yet, we skip enabling that one server with a single clear warning
-- instead of nvim silently trying, failing, and re-trying to spawn it on
-- every matching buffer. Applied to every server (not just gopls) so the
-- same problem can't quietly reappear for any other language later.
local servers = {
  "lua_ls",
  "ts_ls", "html", "cssls", "tailwindcss", "angularls", "emmet_ls", "eslint",
  "clangd",
  "pyright", "ruff",
  "gopls",
}

local function server_executable(name)
  -- vim.lsp.config[name] returns the fully-merged config (our lsp/<name>.lua
  -- + nvim-lspconfig's bundled defaults). cmd is USUALLY a table like
  -- { "gopls" } / { "typescript-language-server", "--stdio" }, so cmd[1] is
  -- the real binary name Neovim will try to spawn. But some server configs
  -- (and this is what actually crashed) specify cmd as a FUNCTION instead —
  -- nvim-lspconfig resolves that lazily, only once the client actually
  -- starts, precisely so it can do dynamic lookup (e.g. clangd picking a
  -- versioned binary). Indexing a function with [1] errors ("attempt to
  -- index field 'cmd' (a function value)"), which is exactly the crash.
  --
  -- We only know how to pre-check the plain-table form. If cmd is a
  -- function (or missing, or malformed) we can't safely predict what it'll
  -- resolve to without calling it ourselves, which risks side effects — so
  -- we just don't block in that case and let vim.lsp.enable try normally.
  local ok, cfg = pcall(function() return vim.lsp.config[name] end)
  if not ok or not cfg or not cfg.cmd then
    return true -- can't determine cmd; don't block enabling, let it try
  end

  local cmd = cfg.cmd
  if type(cmd) ~= "table" or not cmd[1] then
    return true -- function form (or anything unexpected) -- can't pre-check
  end

  return vim.fn.executable(cmd[1]) == 1
end

local to_enable = {}
local missing = {}
for _, name in ipairs(servers) do
  if server_executable(name) then
    table.insert(to_enable, name)
  else
    table.insert(missing, name)
  end
end

if #missing > 0 then
  vim.schedule(function()
    vim.notify(
      "LSP server binary not found, skipping: " .. table.concat(missing, ", ")
        .. "\nInstall via :Mason, or (for Go tools) `go install ...` and ensure $(go env GOPATH)/bin is on PATH.",
      vim.log.levels.WARN
    )
  end)
end

vim.lsp.enable(to_enable)

vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 4 },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.HINT] = "󰠠 ",
      [vim.diagnostic.severity.INFO] = " ",
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = true, header = "", prefix = "" },
})

-- ---------------------------------------------------------------------------
-- LspAttach: keymaps shared by every server. <leader>e stays free for
-- nvim-tree. Language-specific extra keymaps (Go, Java) live in
-- plugins/lang/*.lua and attach via their own LspAttach autocmd.
-- ---------------------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
  callback = function(args)
    local buf = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
    end

    -- Navigation
    map("n", "<leader>ch", vim.lsp.buf.hover, "󰋖  [C]ode [H]over Docs")
    map("n", "<leader>cd", vim.lsp.buf.definition, "󰈮  Go to [C]ode [D]efinition")
    map("n", "<leader>cD", vim.lsp.buf.declaration, "󰈮  Go to [C]ode [[D]]eclaration")
    map("n", "<leader>ci", vim.lsp.buf.implementation, "󰡱  Go to [C]ode [I]mplementation")
    map("n", "<leader>ct", vim.lsp.buf.type_definition, "󰆧  Go to [C]ode [T]ype Def")
    map("n", "<leader>cr", function() require("telescope.builtin").lsp_references() end, "󰈇  Go to [C]ode [R]eferences")
    map("n", "<leader>cI", function() require("telescope.builtin").lsp_implementations() end, "󰡱  Go to [C]ode [I]mplementations")

    -- Refactor
    map("n", "<leader>cR", vim.lsp.buf.rename, "󰏫  Rename Symbol")
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "󰌶  Code Action")

    -- Diagnostics — dso/dsi/dsO/dc/db/dr/dl/dq/dt/dT are DAP (lang/*.lua),
    -- deliberately zero letter overlap with this set; both are buffer-local
    -- and can attach to the same buffer, so an overlap would silently
    -- shadow one or the other (this is what broke <leader>do previously).
    map("n", "<leader>do", vim.diagnostic.open_float, "󰅚  [D]iagnostic [O]pen float")
    map("n", "<leader>dp", vim.diagnostic.goto_prev, "󰮳  [D]iagnostic [P]rev")
    map("n", "<leader>dn", vim.diagnostic.goto_next, "󰮴  [D]iagnostic [N]ext")
    map("n", "<leader>dQ", vim.diagnostic.setloclist, "󰅙  [D]iagnostic [Q]uickfix/loclist")
    map("n", "<leader>dx", "<CMD>ToggleAnyDiagnostics<CR>", "󰸞  [D]iagnostic any-type toggle")

    -- Suppression (§4-7) — see configs/diagnostics.lua for the two
    -- suppression strategies (native inline comment vs session filter).
    map("n", "<leader>di", diagnostics.suppress_native, "󰅜  [D]iagnostic [I]gnore (native comment)")
    map("n", "<leader>dI", diagnostics.suppress_session, "󰅜  [D]iagnostic [I]gnore (session, this code)")
    map("n", "<leader>dC", diagnostics.clear_session, "󰃢  [D]iagnostic ignores [C]lear")
    map("n", "<leader>da", diagnostics.action_menu, "󰍦  [D]iagnostic [A]ctions menu")

    -- Toggles
    map("n", "<leader>dv", function()
      local cfg = vim.diagnostic.config()
      vim.diagnostic.config({ virtual_text = not cfg.virtual_text }, buf)
    end, "󰈈  [D]iagnostic [V]irtual text toggle (buffer)")
    map("n", "<leader>dB", function()
      vim.diagnostic.enable(not vim.diagnostic.is_enabled({ bufnr = buf }), { bufnr = buf })
    end, "󰈉  [D]iagnostic [B]uffer toggle")
    map("n", "<leader>dg", function()
      vim.diagnostic.enable(not vim.diagnostic.is_enabled())
    end, "󰈉  [D]iagnostic [G]lobal toggle")

    -- Format (conform.nvim owns formatting now — see plugins/conform.lua)
    map("n", "<leader>cf", function() require("conform").format({ async = true, bufnr = buf }) end, "󰉿  Format Buffer")

    -- Inlay hints
    map("n", "<leader>cH", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
    end, "󰊈  Toggle Inlay [C]ode [[H]]ints")

    if client.name == "eslint" then
      vim.api.nvim_create_autocmd("BufWritePre", { buffer = buf, command = "EslintFixAll" })
    end
  end,
})
