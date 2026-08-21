-- =============================================================================
-- configs/diagnostics.lua · Controlled diagnostic suppression (§4-7)
--
-- Two independent mechanisms, deliberately kept separate:
--
--   1. NATIVE suppression (M.suppress_native, <leader>di) -- inserts the
--      language/linter's own inline ignore-comment (// @ts-expect-error,
--      # noqa: E501, ---@diagnostic disable-next-line, ...). This is the
--      preferred, source-controlled, diff-visible way to suppress a single
--      known diagnostic -- it lives in the file, travels with the code, and
--      every teammate's editor respects it.
--
--   2. SESSION suppression (M.suppress_session / M.clear_session,
--      <leader>dI / <leader>dC) -- a Neovim-side filter for diagnostics
--      that have no native inline-disable (or where you don't want to
--      touch the file). Filters by (source, code) pair, never by severity
--      or blanket disable -- a real error you haven't explicitly ignored
--      always shows.
--
-- Neither of these ever calls vim.diagnostic.disable(): that hides
-- everything indiscriminately, which is exactly what §7 says not to do.
-- =============================================================================

local M = { ignored = {} } -- set of "source:code" strings, session-only

-- ---------------------------------------------------------------------------
-- Filter engine -- wired into every LSP client's publishDiagnostics handler
-- from configs/lsp.lua. Only strips entries matching an ignored
-- (source, code) pair; everything else passes through untouched.
-- ---------------------------------------------------------------------------
local function key_for(d)
  return tostring(d.source) .. ":" .. tostring(d.code)
end

local function filter(diagnostics)
  if vim.tbl_isempty(M.ignored) then return diagnostics end
  return vim.tbl_filter(function(d)
    return not M.ignored[key_for(d)]
  end, diagnostics)
end

-- ---------------------------------------------------------------------------
-- CRITICAL FIX (stack overflow): capture the *real* default handler BEFORE
-- configs/lsp.lua ever overwrites vim.lsp.handlers["textDocument/publishDiagnostics"]
-- with M.handler. This module is require()'d first thing in configs/lsp.lua,
-- before that overwrite happens, so at the time this line runs the global
-- table still holds Neovim's built-in handler.
--
-- Do NOT call `vim.lsp.handlers["textDocument/publishDiagnostics"](...)`
-- from inside M.handler -- once M.handler is installed as that same handler,
-- looking it up through the global table returns M.handler itself, which
-- then calls itself forever ("vim.schedule callback: stack overflow").
-- Always call the captured local `default_publish_diagnostics` instead.
-- ---------------------------------------------------------------------------
local default_publish_diagnostics =
  vim.lsp.handlers["textDocument/publishDiagnostics"]

-- Per-buffer, per-client cache of the last RAW (pre-filter) notification.
-- Lets us re-apply the ignore-list to already-received diagnostics (e.g.
-- after <leader>dI / <leader>dC) without re-requesting anything from the
-- server, and without touching buffers that were never involved.
local raw_cache = {} -- [bufnr] = { [client_id] = { err, result, ctx, config } }

function M.handler(err, result, ctx, config)
  local bufnr = result and result.uri and vim.uri_to_bufnr(result.uri)

  if bufnr and ctx and ctx.client_id then
    raw_cache[bufnr] = raw_cache[bufnr] or {}
    raw_cache[bufnr][ctx.client_id] = { err = err, result = result, ctx = ctx, config = config }
  end

  if result and result.diagnostics then
    -- Never mutate the table the server/handler chain owns -- copy first.
    result = vim.deepcopy(result)
    result.diagnostics = filter(result.diagnostics)
  end

  default_publish_diagnostics(err, result, ctx, config)
end

-- Clean up the cache when a buffer goes away so it doesn't grow unbounded.
vim.api.nvim_create_autocmd("BufWipeout", {
  group = vim.api.nvim_create_augroup("DiagnosticsRawCacheGC", { clear = true }),
  callback = function(args) raw_cache[args.buf] = nil end,
})

-- ---------------------------------------------------------------------------
-- Refresh -- re-applies the CURRENT M.ignored filter to already-cached raw
-- diagnostics by re-running them through the real default handler (which is
-- what actually calls the public vim.diagnostic.set API under the hood).
-- This replaces the old vim.lsp.util._refresh(...) call: that function is an
-- internal/private API (leading underscore, no :h entry, no stability
-- guarantee across Neovim versions) and it also force-refreshed EVERY
-- loaded buffer regardless of whether it had anything to do with the
-- diagnostic that just changed.
--
-- refresh_buf() only touches the one buffer that changed. refresh_all()
-- still exists for the "global" case (clearing the whole session
-- ignore-list, or the any-type toggle) but even then it only walks buffers
-- we actually have cached LSP diagnostics for -- never every loaded buffer
-- in the session.
-- ---------------------------------------------------------------------------
local function refresh_buf(bufnr)
  local per_client = raw_cache[bufnr]
  if not per_client or not vim.api.nvim_buf_is_loaded(bufnr) then return end
  for _, cached in pairs(per_client) do
    local result = cached.result
    if result and result.diagnostics then
      result = vim.deepcopy(result)
      result.diagnostics = filter(result.diagnostics)
    end
    default_publish_diagnostics(cached.err, result, cached.ctx, cached.config)
  end
end

local function refresh_all()
  for bufnr in pairs(raw_cache) do
    refresh_buf(bufnr)
  end
end

-- ---------------------------------------------------------------------------
-- Diagnostic-under-cursor helper: current line, optionally letting the user
-- choose when several diagnostics stack on one line.
-- ---------------------------------------------------------------------------
local function pick_diagnostic(cb)
  local line = vim.fn.line(".") - 1
  local diags = vim.diagnostic.get(0, { lnum = line })
  if #diags == 0 then
    vim.notify("No diagnostic on this line", vim.log.levels.WARN)
    return
  end
  if #diags == 1 then
    cb(diags[1])
    return
  end
  vim.ui.select(diags, {
    prompt = "Multiple diagnostics on this line -- pick one:",
    format_item = function(d) return string.format("[%s] %s", d.source or "?", d.message) end,
  }, function(choice)
    if choice then cb(choice) end
  end)
end

-- ---------------------------------------------------------------------------
-- SESSION suppression -- generic (source, code) filter, for sources with no
-- native inline-disable comment.
-- ---------------------------------------------------------------------------
function M.suppress_session()
  pick_diagnostic(function(d)
    if not d.code then
      vim.notify("Diagnostic has no code to key off -- use native ignore instead (<leader>di)", vim.log.levels.WARN)
      return
    end
    M.ignored[key_for(d)] = true
    vim.notify(("Session-ignoring %s (%s) -- <leader>dC clears"):format(d.code, d.source or "?"), vim.log.levels.INFO)
    -- Only the current buffer can possibly show this diagnostic changing.
    refresh_buf(vim.api.nvim_get_current_buf())
  end)
end

function M.clear_session()
  M.ignored = {}
  vim.notify("Cleared all session-ignored diagnostics", vim.log.levels.INFO)
  -- Any cached buffer could have had something ignored -- refresh those,
  -- and only those (not every loaded buffer in the session).
  refresh_all()
end

-- ---------------------------------------------------------------------------
-- NATIVE suppression -- dispatch table by LSP client source name. Each
-- entry returns the comment text and where to place it ("above" the
-- current line, or "eol" appended to the current line).
-- ---------------------------------------------------------------------------
local native = {
  ["ts_ls"] = function(d)
    return "// @ts-expect-error " .. (d.message or ""):sub(1, 60), "above"
  end,
  ["eslint"] = function(d)
    local rule = d.code or "eslint"
    return "// eslint-disable-next-line " .. rule, "above"
  end,
  ["Pyright"] = function(d)
    local rule = d.code and ("[" .. d.code .. "]") or ""
    return "  # pyright: ignore" .. rule, "eol"
  end,
  ["Ruff"] = function(d)
    return "  # noqa: " .. (d.code or ""), "eol"
  end,
  ["lua_ls"] = function(d)
    local rule = d.code or "unknown"
    return "---@diagnostic disable-next-line: " .. rule, "above"
  end,
  ["gopls"] = function(d)
    -- gopls itself has no first-class inline-disable; this is the
    -- staticcheck/golangci-lint convention, best-effort only.
    return "//lint:ignore " .. (d.code or "SA0000") .. " reviewed, safe to ignore", "above"
  end,
}

function M.suppress_native()
  pick_diagnostic(function(d)
    local fn = d.source and native[d.source]
    if not fn then
      vim.notify(
        ("No native ignore-comment known for source '%s' -- falling back to session-ignore (<leader>dI)"):format(d.source or "?"),
        vim.log.levels.WARN
      )
      return
    end

    local comment, placement = fn(d)
    local row = d.lnum -- 0-indexed

    if placement == "above" then
      local cur = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
      local indent = cur:match("^%s*") or ""
      vim.api.nvim_buf_set_lines(0, row, row, false, { indent .. comment })
    else -- "eol"
      local cur = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
      vim.api.nvim_buf_set_lines(0, row, row + 1, false, { cur .. comment })
    end

    vim.notify("Inserted native suppress comment for " .. (d.source or "?"), vim.log.levels.INFO)
  end)
end

-- ---------------------------------------------------------------------------
-- <leader>da -- single discoverable entry point into everything above, plus
-- the existing float/toggle actions. Answers §6: "from there I should be
-- able to inspect available actions/suppressions where supported."
-- ---------------------------------------------------------------------------
function M.action_menu()
  local items = {
    { "Open diagnostic float",              vim.diagnostic.open_float },
    { "Ignore (native, insert comment)",    M.suppress_native },
    { "Ignore (session, this code)",        M.suppress_session },
    { "Clear all session ignores",          M.clear_session },
    { "Toggle virtual text (buffer)",       function()
        local cfg = vim.diagnostic.config()
        vim.diagnostic.config({ virtual_text = not cfg.virtual_text }, vim.api.nvim_get_current_buf())
      end },
    { "Toggle diagnostics (this buffer)",   function()
        local buf = vim.api.nvim_get_current_buf()
        vim.diagnostic.enable(not vim.diagnostic.is_enabled({ bufnr = buf }), { bufnr = buf })
      end },
    { "Toggle diagnostics (global)",        function()
        vim.diagnostic.enable(not vim.diagnostic.is_enabled())
      end },
  }
  vim.ui.select(items, {
    prompt = "Diagnostic action:",
    format_item = function(item) return item[1] end,
  }, function(choice)
    if choice then choice[2]() end
  end)
end

-- Kept for backward compatibility with the previous "any"-type preset --
-- now just a thin wrapper over the generic engine, seeded with the two
-- known sources for implicit/explicit `any`.
local any_keys = {
  ["ts_ls:7005"] = true, ["ts_ls:7006"] = true, ["ts_ls:7008"] = true,
  ["ts_ls:7031"] = true, ["ts_ls:7034"] = true,
  ["eslint:@typescript-eslint/no-explicit-any"] = true,
}
local any_active = false

vim.api.nvim_create_user_command("ToggleAnyDiagnostics", function()
  any_active = not any_active
  for k in pairs(any_keys) do
    M.ignored[k] = any_active or nil
  end
  vim.notify("any-type diagnostics: " .. (any_active and "HIDDEN" or "SHOWN"), vim.log.levels.INFO)
  refresh_all()
end, {})

return M
