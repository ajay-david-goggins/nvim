-- =============================================================================
-- lua/postman/parser.lua
-- High-performance Postman Collection (v2.1.0) & Environment JSON Parser
-- =============================================================================

local M = {}

--- Safely decode JSON string or return nil and error
---@param content string
---@return table|nil, string|nil
function M.decode_json(content)
  if not content or content == "" then
    return nil, "Empty JSON content"
  end
  local ok, data = pcall(vim.json.decode, content)
  if not ok then
    return nil, "Invalid JSON: " .. tostring(data)
  end
  return data, nil
end

--- Read file and decode as JSON
---@param filepath string
---@return table|nil, string|nil
function M.read_json_file(filepath)
  local expanded = vim.fn.expand(filepath)
  local f = io.open(expanded, "r")
  if not f then
    return nil, "Could not open file: " .. expanded
  end
  local content = f:read("*a")
  f:close()
  return M.decode_json(content)
end

--- Parse Postman Environment file into a key-value dictionary
--- Supports official Postman Environment exports, Bruno/Insomnia envs, and raw key-value JSON
---@param env_data table
---@return table<string, string>
function M.parse_environment(env_data)
  local vars = {}
  if not env_data then return vars end

  -- Standard Postman Environment: { name = "...", values = [ { key = "...", value = "...", enabled = true } ] }
  if type(env_data.values) == "table" then
    for _, item in ipairs(env_data.values) do
      if item and item.key and (item.enabled == nil or item.enabled == true) then
        vars[item.key] = tostring(item.value or "")
      end
    end
    return vars
  end

  -- Flat key-value dictionary format: { "base_url": "...", "token": "..." }
  for k, v in pairs(env_data) do
    if type(v) ~= "table" and type(v) ~= "function" then
      vars[k] = tostring(v)
    end
  end

  return vars
end

--- Parse collection variables: { variable = [ { key = "...", value = "..." } ] }
---@param collection_data table
---@return table<string, string>
function M.parse_collection_variables(collection_data)
  local vars = {}
  if not collection_data or type(collection_data.variable) ~= "table" then
    return vars
  end
  for _, item in ipairs(collection_data.variable) do
    if item and item.key and (item.disabled == nil or item.disabled == false) then
      vars[item.key] = tostring(item.value or "")
    end
  end
  return vars
end

--- Helper to extract URL string from Postman request.url
---@param url_raw any
---@return string
local function extract_url(url_raw)
  if type(url_raw) == "string" then
    return url_raw
  end
  if type(url_raw) == "table" then
    if url_raw.raw and url_raw.raw ~= "" then
      return url_raw.raw
    end
    -- Fallback: assemble from protocol, host, path
    local proto = url_raw.protocol or "http"
    local host = ""
    if type(url_raw.host) == "table" then
      host = table.concat(url_raw.host, ".")
    elseif type(url_raw.host) == "string" then
      host = url_raw.host
    end
    local path = ""
    if type(url_raw.path) == "table" then
      path = table.concat(url_raw.path, "/")
    elseif type(url_raw.path) == "string" then
      path = url_raw.path
    end
    local full = proto .. "://" .. host
    if path ~= "" then
      if not path:match("^/") then full = full .. "/" end
      full = full .. path
    end
    if type(url_raw.query) == "table" and #url_raw.query > 0 then
      local q_parts = {}
      for _, q in ipairs(url_raw.query) do
        if q.key and not q.disabled then
          table.insert(q_parts, q.key .. "=" .. tostring(q.value or ""))
        end
      end
      if #q_parts > 0 then
        full = full .. "?" .. table.concat(q_parts, "&")
      end
    end
    return full
  end
  return ""
end

--- Extract headers from Postman request.header
---@param headers_raw table|nil
---@return table<string, string>
local function extract_headers(headers_raw)
  local headers = {}
  if type(headers_raw) ~= "table" then return headers end

  for _, h in ipairs(headers_raw) do
    if h and h.key and (h.disabled == nil or h.disabled == false) then
      headers[h.key] = tostring(h.value or "")
    end
  end
  return headers
end

--- Extract auth info from Postman request.auth
---@param auth_raw table|nil
---@param headers table<string, string>
---@return table<string, string>, table|nil
local function process_auth(auth_raw, headers)
  if type(auth_raw) ~= "table" or not auth_raw.type then
    return headers, nil
  end

  local auth_type = auth_raw.type
  local auth_info = { type = auth_type }

  if auth_type == "bearer" and type(auth_raw.bearer) == "table" then
    for _, b in ipairs(auth_raw.bearer) do
      if b.key == "token" or b.type == "string" then
        local token = b.value
        headers["Authorization"] = "Bearer " .. tostring(token or "")
        auth_info.token = token
        break
      end
    end
  elseif auth_type == "basic" and type(auth_raw.basic) == "table" then
    local username, password = "", ""
    for _, b in ipairs(auth_raw.basic) do
      if b.key == "username" then username = tostring(b.value or "") end
      if b.key == "password" then password = tostring(b.value or "") end
    end
    auth_info.username = username
    auth_info.password = password
  elseif auth_type == "apikey" and type(auth_raw.apikey) == "table" then
    local key, val, target = "", "", "header"
    for _, k in ipairs(auth_raw.apikey) do
      if k.key == "key" then key = tostring(k.value or "") end
      if k.key == "value" then val = tostring(k.value or "") end
      if k.key == "in" then target = tostring(k.value or "header") end
    end
    if target == "header" and key ~= "" then
      headers[key] = val
    end
    auth_info.key = key
    auth_info.value = val
    auth_info.target = target
  end

  return headers, auth_info
end

--- Extract body from Postman request.body
---@param body_raw table|nil
---@return string|nil, string
local function extract_body(body_raw)
  if type(body_raw) ~= "table" then return nil, "none" end
  local mode = body_raw.mode or "none"

  if mode == "raw" then
    return body_raw.raw or "", "raw"
  elseif mode == "urlencoded" and type(body_raw.urlencoded) == "table" then
    local parts = {}
    for _, item in ipairs(body_raw.urlencoded) do
      if item and item.key and not item.disabled then
        table.insert(parts, vim.uri_encode(item.key) .. "=" .. vim.uri_encode(tostring(item.value or "")))
      end
    end
    return table.concat(parts, "&"), "urlencoded"
  elseif mode == "formdata" and type(body_raw.formdata) == "table" then
    -- Returned as array of key/values
    local parts = {}
    for _, item in ipairs(body_raw.formdata) do
      if item and item.key and not item.disabled then
        table.insert(parts, item.key .. "=" .. tostring(item.value or ""))
      end
    end
    return table.concat(parts, "&"), "formdata"
  end

  return nil, mode
end

--- Recursively flatten Postman collection items
---@param items table
---@param parent_path string[]
---@param out_list table[]
local function flatten_items(items, parent_path, out_list)
  if type(items) ~= "table" then return end

  for _, item in ipairs(items) do
    if item then
      if item.request then
        -- This is a request item
        local req = item.request
        local method = (type(req) == "table" and req.method) or "GET"
        local url = (type(req) == "table" and extract_url(req.url)) or ""
        local headers = (type(req) == "table" and extract_headers(req.header)) or {}
        local auth_info = nil
        if type(req) == "table" and req.auth then
          headers, auth_info = process_auth(req.auth, headers)
        end
        local body, body_mode = extract_body(type(req) == "table" and req.body or nil)

        local folder_display = #parent_path > 0 and table.concat(parent_path, " / ") or ""

        table.insert(out_list, {
          id = item.id or vim.fn.sha256(item.name .. url),
          name = item.name or "Untitled Request",
          folder = folder_display,
          path = parent_path,
          method = string.upper(method),
          url = url,
          headers = headers,
          auth = auth_info,
          body = body,
          body_mode = body_mode,
          description = (type(req) == "table" and req.description) or item.description,
          raw_item = item,
        })
      elseif item.item and type(item.item) == "table" then
        -- This is a folder
        local next_path = vim.deepcopy(parent_path)
        table.insert(next_path, item.name or "Folder")
        flatten_items(item.item, next_path, out_list)
      end
    end
  end
end

--- Parse an entire Postman Collection JSON structure
---@param collection_data table
---@return { name: string, description: string, variables: table<string, string>, requests: table[] }|nil, string|nil
function M.parse_collection(collection_data)
  if not collection_data then
    return nil, "No collection data provided"
  end

  local info = collection_data.info or {}
  local name = info.name or "Postman Collection"
  local desc = info.description or ""
  local variables = M.parse_collection_variables(collection_data)

  local requests = {}
  if collection_data.item and type(collection_data.item) == "table" then
    flatten_items(collection_data.item, {}, requests)
  end

  return {
    name = name,
    description = desc,
    variables = variables,
    requests = requests,
    raw = collection_data,
  }, nil
end

--- Interpolate variables in string using `{{variable_name}}` syntax
--- Priority: runtime_vars > env_vars > collection_vars
---@param str string|nil
---@param env_vars table<string, string>
---@param collection_vars table<string, string>
---@param runtime_vars table<string, string>
---@return string
function M.interpolate(str, env_vars, collection_vars, runtime_vars)
  if not str or str == "" then return "" end

  local function lookup(key)
    local trimmed = vim.trim(key)
    if runtime_vars and runtime_vars[trimmed] ~= nil then
      return runtime_vars[trimmed]
    end
    if env_vars and env_vars[trimmed] ~= nil then
      return env_vars[trimmed]
    end
    if collection_vars and collection_vars[trimmed] ~= nil then
      return collection_vars[trimmed]
    end
    -- Keep unreplaced or return empty? Keep to make debugging obvious
    return "{{" .. trimmed .. "}}"
  end

  local result = str:gsub("{{%s*([%w_%-%.]+)%s*}}", lookup)
  return result
end

return M
