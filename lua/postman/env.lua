-- =============================================================================
-- lua/postman/env.lua
-- Environment & Variable State Manager (Postman Environments & Token Chaining)
-- =============================================================================

local parser = require("postman.parser")

local M = {
  active_env_file = nil,
  active_env_name = "None (No Environment)",
  env_vars = {},
  collection_vars = {},
  runtime_vars = {},
}

--- Reset runtime variables
function M.clear_runtime_vars()
  M.runtime_vars = {}
end

--- Set a runtime variable (e.g. extracted auth token)
---@param key string
---@param value string|number|boolean
function M.set_var(key, value)
  M.runtime_vars[key] = tostring(value)
  vim.notify("󰄬 Postman Variable Set: " .. key .. " = " .. tostring(value), vim.log.levels.INFO, { title = "Postman Env" })
end

--- Get variable by key checking runtime -> env -> collection
---@param key string
---@return string|nil
function M.get_var(key)
  if M.runtime_vars[key] ~= nil then return M.runtime_vars[key] end
  if M.env_vars[key] ~= nil then return M.env_vars[key] end
  if M.collection_vars[key] ~= nil then return M.collection_vars[key] end
  return nil
end

--- Get all resolved variables merged (for display/debugging)
---@return table<string, { value: string, source: string }>
function M.get_all_resolved()
  local result = {}
  for k, v in pairs(M.collection_vars) do
    result[k] = { value = v, source = "collection" }
  end
  for k, v in pairs(M.env_vars) do
    result[k] = { value = v, source = "environment (" .. M.active_env_name .. ")" }
  end
  for k, v in pairs(M.runtime_vars) do
    result[k] = { value = v, source = "runtime/extracted" }
  end
  return result
end

--- Set collection variables
---@param vars table<string, string>
function M.set_collection_vars(vars)
  M.collection_vars = vars or {}
end

--- Load an environment from a Postman environment JSON file
---@param filepath string
---@return boolean, string|nil
function M.load_env_file(filepath)
  local data, err = parser.read_json_file(filepath)
  if not data then
    return false, err
  end

  local vars = parser.parse_environment(data)
  M.env_vars = vars
  M.active_env_file = filepath
  M.active_env_name = data.name or vim.fn.fnamemodify(filepath, ":t:r")

  vim.notify("󰄬 Active Environment: " .. M.active_env_name .. " (" .. vim.tbl_count(vars) .. " variables)", vim.log.levels.INFO, { title = "Postman Env" })
  return true, nil
end

--- Find environment files in current working directory and home
---@return string[]
function M.find_env_files()
  local patterns = {
    "*environment*.json",
    "*.env.json",
    "*postman_environment*.json",
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
      -- Recursive search in CWD, top-level search in home
      local glob_pat = (root == home) and (pat) or ("**/" .. pat)
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

--- Interactive Environment Selector & Manager
---@param callback? fun(env_name: string)
function M.select_env(callback)
  local files = M.find_env_files()
  local items = {
    { display = "✏️  [Edit] Open environment JSON in split", action = "edit" },
    { display = "➕ [Modify] Edit or add variable interactively", action = "modify" },
    { display = "🚫 [None] Clear active environment", action = "clear" },
  }

  for _, f in ipairs(files) do
    local rel = vim.fn.fnamemodify(f, ":~:.")
    local is_active = (M.active_env_file == f) and " 󰄬 [ACTIVE]" or ""
    table.insert(items, {
      display = "󰒋 " .. rel .. is_active,
      path = f,
      name = vim.fn.fnamemodify(f, ":t:r"),
      action = "select",
    })
  end

  if #files == 0 then
    vim.ui.input({
      prompt = "No environment files detected. Enter path to .postman_environment.json: ",
      completion = "file",
    }, function(path)
      if not path or path == "" then return end
      local ok, err = M.load_env_file(path)
      if not ok then
        vim.notify("Error loading environment: " .. tostring(err), vim.log.levels.ERROR, { title = "Postman Env" })
      elseif callback then
        callback(M.active_env_name)
      end
    end)
    return
  end

  vim.ui.select(items, {
    prompt = "Postman Environment Manager (" .. M.active_env_name .. "): ",
    format_item = function(item) return item.display end,
  }, function(choice)
    if not choice then return end

    if choice.action == "edit" then
      require("postman").edit_env()
      return
    elseif choice.action == "modify" then
      require("postman").modify_var()
      return
    elseif choice.action == "clear" then
      M.env_vars = {}
      M.active_env_file = nil
      M.active_env_name = "None"
      vim.notify("Cleared active Postman environment", vim.log.levels.INFO, { title = "Postman Env" })
      if callback then callback("None") end
      return
    end

    local ok, err = M.load_env_file(choice.path)
    if not ok then
      vim.notify("Error loading environment: " .. tostring(err), vim.log.levels.ERROR, { title = "Postman Env" })
    elseif callback then
      callback(M.active_env_name)
    end
  end)
end

--- Helper: Traverse dot-notation path in a Lua table (e.g. "data.user.token")
---@param tbl table
---@param path_str string
---@return any
local function get_by_path(tbl, path_str)
  local current = tbl
  for part in string.gmatch(path_str, "[^%.%[%]]+") do
    if type(current) ~= "table" then return nil end
    local num = tonumber(part)
    if num and current[num] ~= nil then
      current = current[num]
    else
      current = current[part]
    end
  end
  return current
end

--- Extract variable from a JSON response string using dot notation (e.g. "token" or "data.access_token")
---@param json_str string
---@param json_path string
---@param var_name string
---@return boolean, string|nil
function M.extract_from_json(json_str, json_path, var_name)
  local data, err = parser.decode_json(json_str)
  if not data then
    return false, "Failed to decode response JSON: " .. tostring(err)
  end

  local val = get_by_path(data, json_path)
  if val == nil then
    return false, "Field not found at path: " .. json_path
  end

  M.set_var(var_name, val)
  return true, tostring(val)
end

return M
