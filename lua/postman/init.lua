-- =============================================================================
-- lua/postman/init.lua
-- Blazing Fast, Native Postman Collection & Environment Runner for Neovim
-- =============================================================================

local parser = require("postman.parser")
local env = require("postman.env")
local runner = require("postman.runner")
local ui = require("postman.ui")

local M = {
  active_collection = nil,
  active_collection_file = nil,
}

--- Find all Postman collection files in current working directory and home
---@return string[]
function M.find_collections()
  local patterns = {
    "*postman_collection*.json",
    "*.collection.json",
    "*collection*.json",
  }
  local files = {}
  local seen = {}

  local search_roots = { vim.fn.getcwd() }
  local home = vim.fn.expand("~")
  if vim.fn.getcwd() ~= home then
    table.insert(search_roots, home)
  end

  for _, root in ipairs(search_roots) do
    for _, pat in ipairs(patterns) do
      local glob_pat = (root == home) and pat or ("**/" .. pat)
      local matches = vim.fn.globpath(root, glob_pat, false, true)
      for _, match in ipairs(matches) do
        if not seen[match] and not match:match("/%.git/") and not match:match("/node_modules/") then
          seen[match] = true
          table.insert(files, match)
        end
      end
    end
  end
  return files
end

--- Load a Postman Collection JSON file
---@param filepath string
---@return boolean, string|nil
function M.load_collection(filepath)
  local data, err = parser.read_json_file(filepath)
  if not data then
    return false, err
  end

  local parsed, parse_err = parser.parse_collection(data)
  if not parsed then
    return false, parse_err
  end

  M.active_collection = parsed
  M.active_collection_file = filepath

  -- Sync collection variables into environment state
  env.set_collection_vars(parsed.variables)

  vim.notify(string.format("󰄬 Loaded Postman Collection: '%s' (%d requests)", parsed.name, #parsed.requests), vim.log.levels.INFO, { title = "Postman" })
  return true, nil
end

--- Interactive Collection Selector
---@param callback? fun(col: table)
function M.select_collection(callback)
  local files = M.find_collections()

  if #files == 0 then
    vim.ui.input({
      prompt = "No collection files detected in CWD. Enter path to .postman_collection.json: ",
      completion = "file",
    }, function(path)
      if not path or path == "" then return end
      local ok, err = M.load_collection(path)
      if not ok then
        vim.notify("Failed to load collection: " .. tostring(err), vim.log.levels.ERROR, { title = "Postman" })
      elseif callback and M.active_collection then
        callback(M.active_collection)
      end
    end)
    return
  end

  local items = {}
  for _, f in ipairs(files) do
    local rel = vim.fn.fnamemodify(f, ":.")
    table.insert(items, {
      display = "📦 " .. rel,
      path = f,
    })
  end

  vim.ui.select(items, {
    prompt = "Select Postman Collection: ",
    format_item = function(item) return item.display end,
  }, function(choice)
    if not choice then return end
    local ok, err = M.load_collection(choice.path)
    if not ok then
      vim.notify("Failed to load collection: " .. tostring(err), vim.log.levels.ERROR, { title = "Postman" })
    elseif callback and M.active_collection then
      callback(M.active_collection)
    end
  end)
end

--- Run Postman requests via Telescope
function M.run()
  if M.active_collection then
    ui.open_request_picker(M.active_collection)
  else
    M.select_collection(function(col)
      ui.open_request_picker(col)
    end)
  end
end

--- Select Environment
function M.select_env()
  env.select_env()
end

--- Open an environment file in a split and auto-reload on :w save
---@param filepath string
local function open_env_file_for_editing(filepath)
  vim.cmd("split " .. vim.fn.fnameescape(filepath))
  local bufnr = vim.api.nvim_get_current_buf()

  local group = vim.api.nvim_create_augroup("PostmanEnvAutoReload_" .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    buffer = bufnr,
    callback = function()
      local ok, err = env.load_env_file(filepath)
      if ok then
        vim.notify(string.format("󰄬 Reloaded %d variables from %s!", vim.tbl_count(env.env_vars), env.active_env_name), vim.log.levels.INFO, { title = "Postman Env" })
      else
        vim.notify("Error reloading environment: " .. tostring(err), vim.log.levels.ERROR, { title = "Postman Env" })
      end
    end,
  })

  vim.notify("Editing: " .. vim.fn.fnamemodify(filepath, ":t") .. " (Auto-reloads on :w)", vim.log.levels.INFO, { title = "Postman Env" })
end

--- Edit the active environment file or pick one to edit
function M.edit_env()
  local file = env.active_env_file
  if not file or file == "" then
    local files = env.find_env_files()
    if #files == 0 then
      vim.notify("No environment files found to edit", vim.log.levels.WARN, { title = "Postman" })
      return
    end

    vim.ui.select(files, {
      prompt = "Select Environment File to Edit: ",
      format_item = function(item) return "󰒋 " .. vim.fn.fnamemodify(item, ":~:.") end,
    }, function(choice)
      if not choice then return end
      open_env_file_for_editing(choice)
    end)
    return
  end

  open_env_file_for_editing(file)
end

--- Interactive variable modifier
function M.modify_var()
  local all_vars = env.get_all_resolved()
  local items = {
    { display = "➕ [New Variable] Add a new custom variable", key = nil },
  }

  for k, v in pairs(all_vars) do
    table.insert(items, {
      display = string.format("󰒋 {{%s}} = %s  [%s]", k, v.value, v.source),
      key = k,
      val = v.value,
    })
  end

  vim.ui.select(items, {
    prompt = "Select Variable to Modify: ",
    format_item = function(item) return item.display end,
  }, function(choice)
    if not choice then return end

    if not choice.key then
      -- Prompt for new variable name
      vim.ui.input({ prompt = "Enter variable name: " }, function(new_key)
        if not new_key or new_key == "" then return end
        vim.ui.input({ prompt = "Enter value for {{" .. new_key .. "}}: " }, function(new_val)
          if new_val == nil then return end
          env.set_var(new_key, new_val)
        end)
      end)
    else
      -- Prompt with current value as default
      vim.ui.input({
        prompt = string.format("Enter new value for {{%s}}: ", choice.key),
        default = choice.val or "",
      }, function(new_val)
        if new_val == nil then return end
        env.set_var(choice.key, new_val)
      end)
    end
  end)
end

--- View or reopen last response
function M.view_response()
  if runner.last_response then
    ui.render_response(runner.last_response)
  else
    vim.notify("No previous Postman response found. Run a request with <leader>pr first.", vim.log.levels.WARN, { title = "Postman" })
  end
end

--- Show active variables
function M.show_variables()
  ui.show_variables()
end

--- Extract variable from current response
function M.extract_variable()
  if not runner.last_response then
    vim.notify("No active response to extract from. Run a request first.", vim.log.levels.WARN, { title = "Postman" })
    return
  end
  ui.prompt_extract_variable(runner.last_response.raw_body or runner.last_response.body)
end

--- Export current Postman collection into standard .http file (for Kulala / JetBrains / VS Code)
---@param output_file? string
function M.export_to_http(output_file)
  if not M.active_collection then
    vim.notify("No active collection loaded to export. Load one first.", vim.log.levels.WARN, { title = "Postman" })
    return
  end

  local target = output_file
  if not target or target == "" then
    local base_name = M.active_collection_file and vim.fn.fnamemodify(M.active_collection_file, ":t:r") or "collection"
    target = base_name .. ".http"
  end

  local lines = {
    "### " .. M.active_collection.name,
    "### Auto-generated from Postman Collection",
    "",
  }

  for _, req in ipairs(M.active_collection.requests) do
    table.insert(lines, "### " .. (req.folder ~= "" and (req.folder .. " > ") or "") .. req.name)
    table.insert(lines, req.method .. " " .. req.url)
    for hk, hv in pairs(req.headers or {}) do
      table.insert(lines, hk .. ": " .. hv)
    end
    if req.body and req.body ~= "" then
      table.insert(lines, "")
      local b_lines = vim.split(req.body, "\r?\n")
      for _, bl in ipairs(b_lines) do table.insert(lines, bl) end
    end
    table.insert(lines, "")
    table.insert(lines, "")
  end

  local f = io.open(target, "w")
  if not f then
    vim.notify("Could not write to file: " .. target, vim.log.levels.ERROR, { title = "Postman" })
    return
  end
  f:write(table.concat(lines, "\n"))
  f:close()

  vim.notify("󰄬 Exported collection to " .. target, vim.log.levels.INFO, { title = "Postman Export" })
end

--- Open History Picker
function M.history()
  ui.open_history_picker()
end

--- Open Request Studio (Craft/edit request & payload at runtime)
---@param req? table
function M.studio(req)
  ui.open_request_studio(req)
end

--- Setup and configure plugin
---@param opts? table
function M.setup(opts)
  opts = opts or {}
  if opts.insecure ~= nil then runner.insecure = opts.insecure end
  if opts.timeout ~= nil then runner.timeout = opts.timeout end

  -- User commands
  vim.api.nvim_create_user_command("PostmanRun", function() M.run() end, { desc = "Run Postman request via Telescope" })
  vim.api.nvim_create_user_command("PostmanSelectCollection", function() M.select_collection() end, { desc = "Select Postman collection JSON" })
  vim.api.nvim_create_user_command("PostmanSelectEnv", function() M.select_env() end, { desc = "Select Postman environment JSON" })
  vim.api.nvim_create_user_command("PostmanEditEnv", function() M.edit_env() end, { desc = "Edit active Postman environment JSON" })
  vim.api.nvim_create_user_command("PostmanModifyVar", function() M.modify_var() end, { desc = "Modify or add Postman variable interactively" })
  vim.api.nvim_create_user_command("PostmanResponse", function() M.view_response() end, { desc = "View last Postman response" })
  vim.api.nvim_create_user_command("PostmanVariables", function() M.show_variables() end, { desc = "Show active Postman variables" })
  vim.api.nvim_create_user_command("PostmanExtractVar", function() M.extract_variable() end, { desc = "Extract variable from response" })
  vim.api.nvim_create_user_command("PostmanHistory", function() M.history() end, { desc = "Browse Postman request history" })
  vim.api.nvim_create_user_command("PostmanStudio", function() M.studio() end, { desc = "Open Request Studio (edit payload at runtime)" })
  vim.api.nvim_create_user_command("PostmanExportHttp", function(args) M.export_to_http(args.args) end, { nargs = "?", desc = "Export collection to .http file" })
  vim.api.nvim_create_user_command("PostmanSetVar", function(args)
    local k, v = args.args:match("^(%S+)%s+(.+)$")
    if k and v then
      env.set_var(k, v)
    else
      vim.notify("Usage: :PostmanSetVar <key> <value>", vim.log.levels.ERROR)
    end
  end, { nargs = "+", desc = "Set a Postman runtime variable" })

  -- Global fallback keymaps
  local K = vim.keymap.set
  local ko = { silent = true }
  K("n", "<leader>pr", function() M.run() end, vim.tbl_extend("force", ko, { desc = "  [P]ostman [R]un request (Telescope)" }))
  K("n", "<leader>pc", function() M.select_collection() end, vim.tbl_extend("force", ko, { desc = "  [P]ostman select [C]ollection" }))
  K("n", "<leader>pe", function() M.select_env() end, vim.tbl_extend("force", ko, { desc = "  [P]ostman select [E]nvironment" }))
  K("n", "<leader>pE", function() M.edit_env() end, vim.tbl_extend("force", ko, { desc = "  [P]ostman [E]dit environment JSON (split)" }))
  K("n", "<leader>pm", function() M.modify_var() end, vim.tbl_extend("force", ko, { desc = "  [P]ostman [M]odify variable interactively" }))
  K("n", "<leader>pw", function() M.studio() end, vim.tbl_extend("force", ko, { desc = "  [P]ostman [W]orkspace / Request Studio (edit payload)" }))
  K("n", "<leader>ph", function() M.history() end, vim.tbl_extend("force", ko, { desc = "  [P]ostman [H]istory browser" }))
  K("n", "<leader>pv", function() M.view_response() end, vim.tbl_extend("force", ko, { desc = "  [P]ostman [V]iew last response" }))
  K("n", "<leader>px", function() M.extract_variable() end, vim.tbl_extend("force", ko, { desc = "  [P]ostman e[X]tract var from response" }))
  K("n", "<leader>p?", function() M.show_variables() end, vim.tbl_extend("force", ko, { desc = "  [P]ostman show active variables" }))
end

return M
