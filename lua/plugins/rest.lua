-- =============================================================================
-- plugins/rest.lua · kulala.nvim -- "Postman inside Neovim"
--
-- Requires: Neovim 0.12+, curl on PATH (kulala downloads its own small
-- "kulala-core" backend via curl the first time you run a request -- no
-- manual step needed, just don't be surprised by a one-time download).
--
-- Write requests in plain .http (or .rest) files, run the one under your
-- cursor, get a formatted response in a split -- headers, body, status --
-- with syntax highlighting and JSON pretty-printing. No context switch to a
-- separate GUI app.
--
-- WHERE YOUR REQUESTS LIVE: anywhere you want, as plain text files ending in
-- .http or .rest. Example layout (entirely your choice):
--
--   ~/projects/calonenextapp/api/
--     ├── http-client.env.json   -- environments (see below)
--     ├── auth.http
--     ├── patients.http
--     └── family-group.http
--
-- A MINIMAL EXAMPLE REQUEST FILE (patients.http):
--
--   @baseUrl = {{host}}/api/method
--
--   ### Get patient by id
--   GET {{baseUrl}}/calonenextapp.api.patient.get?id=123
--   Authorization: Bearer {{token}}
--
--   ### Create a family group member
--   POST {{baseUrl}}/calonenextapp.api.family_group.add_member
--   Content-Type: application/json
--   Authorization: Bearer {{token}}
--
--   {
--     "family_id": "FG-0001",
--     "name": "Test Member"
--   }
--
-- `###` starts a new named request in the same file -- put your cursor
-- inside any block and hit <leader>rr.
--
-- ENVIRONMENTS ("Postman environments"): a sibling http-client.env.json,
-- e.g.:
--
--   {
--     "dev":        { "host": "http://localhost:8000", "token": "dev-token" },
--     "staging":    { "host": "https://staging.calonenext.example", "token": "{{$processEnv STAGING_TOKEN}}" },
--     "production": { "host": "https://calonenext.example", "token": "{{$processEnv PROD_TOKEN}}" }
--   }
--
-- Switch between them with <leader>re. {{$processEnv NAME}} pulls a real
-- shell environment variable at request-time, so secrets never have to sit
-- in the file in plaintext.
-- =============================================================================

return {
  "mistweaverco/kulala.nvim",
  ft = { "http", "rest" }, -- lazy: only loads when you open a .http/.rest file
  opts = {
    default_env = "dev",
    environment_scope = "b", -- "b" = per-buffer selected env, "g" = global

    ui = {
      display_mode = "split", -- vs "float"
      split_direction = "right",
    },

    response_format = {
      indent = 2,
      expand_tabs = true,
      sort_keys = false,
    },

    -- We define our own explicit, buffer-local keymaps below instead of
    -- kulala's global set, so nothing here can ever shadow a mapping in a
    -- non-.http buffer.
    global_keymaps = false,
  },
  config = function(_, opts)
    require("kulala").setup(opts)

    local kulala = require("kulala")
    local map = vim.keymap.set

    -- Scratchpad: a throwaway .http buffer for a quick one-off request you
    -- don't want to save anywhere -- the closest thing here to Postman's
    -- "untitled request" tab. Global, since you'll invoke it from whatever
    -- buffer you're already in, not from inside an existing .http file.
    map("n", "<leader>rs", function() kulala.scratchpad() end,{ desc =  "󰃃  [R]est: [S]cratchpad (quick one-off request)" })

    -- Extracted so we can apply it two ways: (1) for every FUTURE .http/
    -- .rest buffer via the autocmd below, and (2) immediately, right now,
    -- for the CURRENT buffer -- because if this plugin was just lazy-loaded
    -- by lazy.nvim's `ft = {"http","rest"}` trigger, the FileType event for
    -- THIS buffer already fired before this config() function ever ran, so
    -- an autocmd registered only now would silently miss it. Without this,
    -- the first .http file you ever open in a session gets no keymaps at
    -- all -- <leader>r falls through to plain <Space> (cursor right) then
    -- bare "r" (native replace-char), which is exactly the "it tries to
    -- replace/rename the character" symptom.
    local function attach(buf)
      local bmap = function(lhs, rhs, desc)
        map("n", lhs, rhs, { buffer = buf, silent = true, desc = desc })
      end

      -- Run
      bmap("<leader>rr", kulala.run, "󰖟  [R]est: [R]un request under cursor")
      bmap("<leader>rA", kulala.run_all, "󰖟  [R]est: run [A]ll requests in file")
      bmap("<leader>rx", kulala.replay, "󰑙  [R]est: re[X]ecute last request")

      -- Navigate between ### request blocks
      bmap("<leader>rn", kulala.jump_next, "󰒭  [R]est: [N]ext request")
      bmap("<leader>rp", kulala.jump_prev, "󰒮  [R]est: [P]rev request")
      bmap("<leader>rF", kulala.search, "󰍉  [R]est: [F]ind named request (telescope)")

      -- Response view -- toggles between body and headers of the last run
      bmap("<leader>rt", kulala.toggle_view, "󰓡  [R]est: [T]oggle body/headers view")
      bmap("<leader>rS", kulala.show_stats, "󰄨  [R]est: show [S]tats (timing/size) of last run")

      -- Environments -- the Postman "environment switcher" equivalent.
      -- Only works if an http-client.env.json sits next to your .http
      -- file; omit the arg and kulala prompts you (telescope or vim.ui.select).
      bmap("<leader>re", function() kulala.set_selected_env() end, "󰡨  [R]est: switch [E]nvironment")

      -- Interop with the rest of the world
      bmap("<leader>rc", kulala.copy, "󰆍  [R]est: [C]opy current request as cURL")
      bmap("<leader>ri", kulala.from_curl, "󰆍  [R]est: [I]mport cURL from clipboard")
      bmap("<leader>rd", kulala.download_graphql_schema, "󰡷  [R]est: [D]ownload GraphQL schema (cursor on request)")

      -- Inspect the fully-resolved request (variables expanded) before
      -- sending -- handy for double-checking auth headers/tokens.
      bmap("<leader>rI", kulala.inspect, "󰍉  [R]est: [I]nspect resolved request")

      -- Close the response split (and the .http buffer, if this one isn't it)
      bmap("<leader>rq", kulala.close, "󰅗  [R]est: [Q]uit response view")
    end

    -- (1) Every future .http/.rest buffer.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "http", "rest" },
      group = vim.api.nvim_create_augroup("KulalaRestKeymaps", { clear = true }),
      callback = function(args) attach(args.buf) end,
    })

    -- (2) The buffer that's open RIGHT NOW, if this config() run was itself
    -- triggered by opening a .http/.rest file (the race described above).
    local cur = vim.api.nvim_get_current_buf()
    if vim.bo[cur].filetype == "http" or vim.bo[cur].filetype == "rest" then
      attach(cur)
    end
  end,
}
