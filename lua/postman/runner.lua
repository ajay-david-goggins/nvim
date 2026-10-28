-- =============================================================================
-- lua/postman/runner.lua
-- Asynchronous cURL Request Executor, Metrics Profiler & Persistent History
-- =============================================================================

local parser = require("postman.parser")
local env = require("postman.env")

local history_file = vim.fn.stdpath("state") .. "/postman_history.json"

local M = {
  insecure = true, -- Allow self-signed dev certificates by default
  timeout = 30,    -- Default timeout in seconds
  last_request = nil,
  last_response = nil,
  history = {},
}

--- Load history from disk
function M.load_history()
  local f = io.open(history_file, "r")
  if not f then return end
  local content = f:read("*a")
  f:close()
  if content and content ~= "" then
    local ok, data = pcall(vim.json.decode, content)
    if ok and type(data) == "table" then
      M.history = data
      if #M.history > 0 and not M.last_response then
        M.last_response = M.history[1].response
        M.last_request = M.history[1].request
      end
    end
  end
end

--- Save history to disk
function M.save_history()
  local f = io.open(history_file, "w")
  if not f then return end
  local ok, enc = pcall(vim.json.encode, M.history)
  if ok and enc then
    f:write(enc)
  end
  f:close()
end

--- Format byte size into human readable string
---@param bytes number
---@return string
local function format_bytes(bytes)
  if not bytes or bytes <= 0 then return "0 B" end
  local units = { "B", "KB", "MB", "GB" }
  local i = 1
  while bytes >= 1024 and i < #units do
    bytes = bytes / 1024
    i = i + 1
  end
  return string.format("%.2f %s", bytes, units[i])
end

--- Format milliseconds into human readable string
---@param seconds number
---@return string
local function format_duration(seconds)
  if not seconds then return "0ms" end
  local ms = math.floor(seconds * 1000 + 0.5)
  if ms >= 1000 then
    return string.format("%.2fs", seconds)
  end
  return string.format("%dms", ms)
end

--- Pretty-print JSON string with indentation
---@param raw_json string
---@return string, boolean
local function format_json(raw_json)
  if not raw_json or raw_json:match("^%s*$") then
    return raw_json or "", false
  end

  local ok, decoded = pcall(vim.json.decode, raw_json)
  if not ok then
    return raw_json, false
  end

  local ok_enc, formatted = pcall(vim.fn.json_encode, decoded)
  if not ok_enc then
    return raw_json, true
  end

  if vim.fn.executable("python3") == 1 then
    local p_res = vim.system({ "python3", "-m", "json.tool", "--indent", "2" }, { stdin = raw_json, text = true }):wait()
    if p_res.code == 0 and p_res.stdout and p_res.stdout ~= "" then
      return p_res.stdout, true
    end
  end

  return formatted, true
end

--- Execute a Postman request asynchronously
---@param request_item table Parsed request from parser.lua
---@param callback fun(response: table|nil, err: string|nil)
function M.execute(request_item, callback)
  if not request_item then
    callback(nil, "No request provided")
    return
  end

  local env_vars = env.env_vars
  local col_vars = env.collection_vars
  local run_vars = env.runtime_vars

  -- Resolve variables in URL, headers, and body
  local resolved_url = parser.interpolate(request_item.url, env_vars, col_vars, run_vars)
  if resolved_url == "" then
    callback(nil, "Empty request URL")
    return
  end

  if not resolved_url:match("^https?://") then
    resolved_url = "http://" .. resolved_url
  end

  local resolved_headers = {}
  for k, v in pairs(request_item.headers or {}) do
    local rk = parser.interpolate(k, env_vars, col_vars, run_vars)
    local rv = parser.interpolate(v, env_vars, col_vars, run_vars)
    resolved_headers[rk] = rv
  end

  local resolved_body = nil
  if request_item.body and request_item.body ~= "" then
    resolved_body = parser.interpolate(request_item.body, env_vars, col_vars, run_vars)
  end

  if resolved_body and not resolved_headers["Content-Type"] and not resolved_headers["content-type"] then
    if resolved_body:match("^%s*[%{%[]") then
      resolved_headers["Content-Type"] = "application/json"
    end
  end

  local pretty_req_body = resolved_body
  if resolved_body and resolved_body:match("^%s*[%{%[]") then
    local formatted, ok = format_json(resolved_body)
    if ok then pretty_req_body = formatted end
  end

  M.last_request = {
    name = request_item.name or "API Request",
    method = request_item.method or "GET",
    url = resolved_url,
    raw_url = request_item.url,
    headers = resolved_headers,
    body = resolved_body,
    formatted_body = pretty_req_body,
    timestamp = os.date("%H:%M:%S"),
    date = os.date("%Y-%m-%d"),
  }

  local header_file = vim.fn.tempname()
  local body_file = nil

  local cmd = {
    "curl",
    "-sS",
    "-D", header_file,
    "-X", request_item.method,
    "--max-time", tostring(M.timeout),
    "--write-out", "\n---METRICS---\n%{http_code}\n%{time_total}\n%{size_download}\n%{content_type}",
  }

  if M.insecure then
    table.insert(cmd, "-k")
  end

  for hk, hv in pairs(resolved_headers) do
    table.insert(cmd, "-H")
    table.insert(cmd, hk .. ": " .. hv)
  end

  if resolved_body and request_item.method ~= "GET" and request_item.method ~= "HEAD" then
    body_file = vim.fn.tempname()
    local bf = io.open(body_file, "w")
    if bf then
      bf:write(resolved_body)
      bf:close()
      table.insert(cmd, "--data-binary")
      table.insert(cmd, "@" .. body_file)
    end
  end

  table.insert(cmd, resolved_url)

  local start_time = vim.uv.hrtime()

  vim.notify("󰑮 [" .. request_item.method .. "] " .. resolved_url .. "...", vim.log.levels.INFO, { title = "Postman" })

  vim.system(cmd, { text = true }, function(result)
    local elapsed_ns = vim.uv.hrtime() - start_time
    local fallback_seconds = elapsed_ns / 1e9

    if body_file then
      pcall(os.remove, body_file)
    end

    local response_headers_raw = ""
    local hf = io.open(header_file, "r")
    if hf then
      response_headers_raw = hf:read("*a")
      hf:close()
      pcall(os.remove, header_file)
    end

    local raw_out = result.stdout or ""
    local err_out = result.stderr or ""

    if result.code ~= 0 and raw_out == "" then
      vim.schedule(function()
        callback(nil, "cURL Error (" .. result.code .. "): " .. (err_out ~= "" and err_out or "Connection failed"))
      end)
      return
    end

    local body_part = raw_out
    local status_code = 0
    local time_total = fallback_seconds
    local size_download = #raw_out
    local content_type = ""

    local split_pos = raw_out:find("\n---METRICS---\n")
    if split_pos then
      body_part = raw_out:sub(1, split_pos - 1)
      local metrics_str = raw_out:sub(split_pos + #"---METRICS---\n" + 1)
      local lines = vim.split(metrics_str, "\n", { trimempty = true })
      status_code = tonumber(lines[1]) or 0
      time_total = tonumber(lines[2]) or fallback_seconds
      size_download = tonumber(lines[3]) or #body_part
      content_type = lines[4] or ""
    end

    local header_lines = vim.split(response_headers_raw, "\r?\n", { trimempty = true })
    local http_status_line = ""
    local parsed_headers = {}

    for _, line in ipairs(header_lines) do
      if line:match("^HTTP/") then
        http_status_line = line
      else
        local hk, hv = line:match("^([%w_%-]+):%s*(.*)$")
        if hk and hv then
          parsed_headers[hk] = hv
        end
      end
    end

    local is_json = content_type:match("application/json") ~= nil
      or body_part:match("^%s*[%{%[]") ~= nil
    local formatted_body = body_part
    if is_json then
      local pretty, ok = format_json(body_part)
      if ok then
        formatted_body = pretty
      end
    end

    local resp_data = {
      status_code = status_code,
      status_line = http_status_line ~= "" and http_status_line or ("HTTP " .. tostring(status_code)),
      time_duration = format_duration(time_total),
      size_formatted = format_bytes(size_download),
      content_type = content_type,
      headers_raw = response_headers_raw,
      headers = parsed_headers,
      body = formatted_body,
      raw_body = body_part,
      is_json = is_json,
      request = M.last_request,
      timestamp = os.date("%H:%M:%S"),
    }

    M.last_response = resp_data

    -- Append to persistent history (keep last 50)
    table.insert(M.history, 1, {
      name = request_item.name or "API Request",
      method = request_item.method or "GET",
      url = resolved_url,
      raw_url = request_item.url,
      status_code = status_code,
      time = resp_data.time_duration,
      timestamp = resp_data.timestamp,
      date = os.date("%Y-%m-%d"),
      request = M.last_request,
      response = resp_data,
    })
    if #M.history > 50 then
      table.remove(M.history)
    end
    M.save_history()

    vim.schedule(function()
      callback(resp_data, nil)
    end)
  end)
end

-- Initialize history on startup
M.load_history()

return M
