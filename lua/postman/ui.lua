-- =============================================================================
-- lua/postman/ui.lua
-- Full-Fledged Postman Studio: Multi-Tab Response View, Request Editor & History
-- =============================================================================

local runner = require("postman.runner")
local env = require("postman.env")
local parser = require("postman.parser")

local M = {
  response_bufnr = nil,
  response_winid = nil,
  studio_bufnr = nil,
  studio_winid = nil,
  current_tab = "response", -- "response", "request", "headers"
}

--- Method badge icons
local METHOD_ICONS = {
  GET    = "󰄬 [GET]   ",
  POST   = "󰐕 [POST]  ",
  PUT    = "󰦨 [PUT]   ",
  PATCH  = "󰛿 [PATCH] ",
  DELETE = "󰆴 [DELETE]",
  HEAD   = "󰈈 [HEAD]  ",
}

--- Open or reuse response window adaptively (responsive to width)
---@return number, number (bufnr, winid)
local function get_or_create_response_window()
  if M.response_winid and vim.api.nvim_win_is_valid(M.response_winid) then
    if M.response_bufnr and vim.api.nvim_buf_is_valid(M.response_bufnr) then
      vim.api.nvim_set_current_win(M.response_winid)
      return M.response_bufnr, M.response_winid
    end
  end

  local total_width = vim.o.columns
  if total_width >= 110 then
    vim.cmd("botright vsplit")
    local split_w = math.floor(total_width * 0.48)
    vim.cmd("vertical resize " .. split_w)
  else
    vim.cmd("botright split")
    local split_h = math.floor(vim.o.lines * 0.45)
    vim.cmd("resize " .. split_h)
  end

  local new_winid = vim.api.nvim_get_current_win()
  local new_bufnr = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_win_set_buf(new_winid, new_bufnr)

  vim.wo[new_winid].number = true
  vim.wo[new_winid].relativenumber = false
  vim.wo[new_winid].wrap = true
  vim.wo[new_winid].signcolumn = "no"

  vim.bo[new_bufnr].buftype = "nofile"
  vim.bo[new_bufnr].bufhidden = "wipe"
  vim.bo[new_bufnr].swapfile = false
  vim.api.nvim_buf_set_name(new_bufnr, "[Postman Response]")

  M.response_bufnr = new_bufnr
  M.response_winid = new_winid

  return new_bufnr, new_winid
end

--- Render the response data into the dedicated split window
---@param resp table
function M.render_response(resp)
  if not resp then return end

  local bufnr, winid = get_or_create_response_window()

  local status_icon = (resp.status_code >= 200 and resp.status_code < 300) and "󰄬"
    or (resp.status_code >= 300 and resp.status_code < 400) and "󰁔"
    or "󰅚"

  local req = resp.request or {}
  local header_sep = string.rep("═", 78)
  local thin_sep   = string.rep("─", 78)

  local tab_req = (M.current_tab == "request") and "👉 [1] Request Sent (ACTIVE)" or "[1] Request Sent"
  local tab_res = (M.current_tab == "response") and "👉 [2] Response Body (ACTIVE)" or "[2] Response Body"
  local tab_hdr = (M.current_tab == "headers") and "👉 [3] Response Headers (ACTIVE)" or "[3] Response Headers"

  local lines = {
    "// " .. header_sep,
    string.format("// %s STATUS: %d (%s)  │  󱎫 TIME: %s  │  󰉉 SIZE: %s  │  󰅐 %s",
      status_icon,
      resp.status_code,
      resp.status_line:match("^HTTP/%S+%s+%d+%s*(.*)$") or "OK",
      resp.time_duration,
      resp.size_formatted,
      resp.timestamp
    ),
    string.format("// 󰑮 [%s] %s", req.method or "GET", req.url or ""),
    "// " .. thin_sep,
    string.format("// 📑 TABS: %s  │  %s  │  %s", tab_req, tab_res, tab_hdr),
    "// ⌨️  KEYS: [1/2/3] Switch Tabs  [e] Edit in Studio  [r] Re-run  [y] Copy  [q] Close",
    "// " .. header_sep,
    "",
  }

  if M.current_tab == "request" then
    -- Outgoing Payload Tab
    table.insert(lines, "// ─── OUTGOING REQUEST HEADERS ──────────────────────────────────────────────────")
    for hk, hv in pairs(req.headers or {}) do
      table.insert(lines, string.format("// %s: %s", hk, hv))
    end
    table.insert(lines, "// ──────────────────────────────────────────────────────────────────────────────")
    table.insert(lines, "// ─── OUTGOING REQUEST BODY (PAYLOAD SENT) ─────────────────────────────────────")
    table.insert(lines, "")

    local req_body = req.formatted_body or req.body or "(No Request Body Sent)"
    local r_lines = vim.split(req_body, "\r?\n")
    for _, l in ipairs(r_lines) do
      table.insert(lines, l)
    end

    vim.bo[bufnr].filetype = "json"

  elseif M.current_tab == "headers" then
    -- Response Headers Tab
    table.insert(lines, "// ─── FULL HTTP RESPONSE HEADERS ───────────────────────────────────────────────")
    table.insert(lines, "// STATUS: " .. resp.status_line)
    table.insert(lines, "")
    local h_lines = vim.split(resp.headers_raw or "", "\r?\n", { trimempty = true })
    for _, hl in ipairs(h_lines) do
      table.insert(lines, hl)
    end

    vim.bo[bufnr].filetype = "text"

  else
    -- Response Body Tab (Default)
    local body_lines = vim.split(resp.body or "(Empty Response Body)", "\r?\n")
    for _, bl in ipairs(body_lines) do
      table.insert(lines, bl)
    end

    if resp.is_json then
      vim.bo[bufnr].filetype = "json"
    elseif resp.content_type:match("html") then
      vim.bo[bufnr].filetype = "html"
    elseif resp.content_type:match("xml") then
      vim.bo[bufnr].filetype = "xml"
    else
      vim.bo[bufnr].filetype = "text"
    end
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  -- Keybindings for the Response window
  local function bkey(key, fn, desc)
    vim.keymap.set("n", key, fn, { buffer = bufnr, silent = true, desc = desc })
  end

  bkey("q", function()
    if winid and vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_win_close(winid, true)
    end
  end, "Close response")

  -- Tab switching
  bkey("1", function()
    M.current_tab = "request"
    M.render_response(resp)
  end, "Show Request Payload")

  bkey("2", function()
    M.current_tab = "response"
    M.render_response(resp)
  end, "Show Response Body")

  bkey("3", function()
    M.current_tab = "headers"
    M.render_response(resp)
  end, "Show Response Headers")

  bkey("<Tab>", function()
    if M.current_tab == "response" then M.current_tab = "request"
    elseif M.current_tab == "request" then M.current_tab = "headers"
    else M.current_tab = "response" end
    M.render_response(resp)
  end, "Cycle Tabs")

  -- Open in Request Studio for editing payload at runtime
  bkey("e", function()
    M.open_request_studio(req)
  end, "Edit Request in Studio")

  -- Yank current tab content
  bkey("y", function()
    local text = (M.current_tab == "request") and (req.formatted_body or req.body or "")
      or (M.current_tab == "headers") and (resp.headers_raw or "")
      or (resp.body or "")
    vim.fn.setreg("+", text)
    vim.fn.setreg('"', text)
    vim.notify("󰄬 Copied " .. M.current_tab .. " to clipboard!", vim.log.levels.INFO, { title = "Postman" })
  end, "Copy tab content")

  -- Extract variable from response
  bkey("x", function()
    M.prompt_extract_variable(resp.raw_body or resp.body)
  end, "Extract variable from JSON")

  -- Re-run request
  bkey("r", function()
    if req and runner.last_request then
      vim.notify("Re-running [" .. req.method .. "] " .. req.url .. "...", vim.log.levels.INFO, { title = "Postman" })
      runner.execute({
        name = req.name or "Last Request",
        method = req.method,
        url = req.url,
        headers = req.headers,
        body = req.body,
      }, function(new_resp, err)
        if err then
          vim.notify(err, vim.log.levels.ERROR, { title = "Postman" })
        else
          M.render_response(new_resp)
        end
      end)
    end
  end, "Re-run request")

  vim.api.nvim_set_current_win(winid)
  vim.api.nvim_win_set_cursor(winid, { 1, 0 })
end

--- Open the Interactive Request Studio (Edit payload & headers at runtime)
---@param req? table
function M.open_request_studio(req)
  local target_req = req or runner.last_request or {
    name = "Custom Request",
    method = "POST",
    url = "{{base_url}}/api/method/calonenextapp.api.auth.login_with_password",
    headers = {
      ["Content-Type"] = "application/json",
      ["Authorization"] = "Bearer {{token}}",
    },
    body = "{\n  \"usr\": \"{{username}}\",\n  \"login_type\": \"facility\"\n}",
  }

  local total_width = vim.o.columns
  if total_width >= 110 then
    vim.cmd("topleft vsplit")
    local split_w = math.floor(total_width * 0.50)
    vim.cmd("vertical resize " .. split_w)
  else
    vim.cmd("topleft split")
    local split_h = math.floor(vim.o.lines * 0.50)
    vim.cmd("resize " .. split_h)
  end

  local winid = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_win_set_buf(winid, bufnr)
  vim.api.nvim_buf_set_name(bufnr, "[Postman Request Studio]")

  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "http"

  local lines = {
    "### " .. (target_req.name or "Request Studio"),
    (target_req.method or "POST") .. " " .. (target_req.url or "{{base_url}}/api/method/..."),
  }

  for hk, hv in pairs(target_req.headers or {}) do
    table.insert(lines, string.format("%s: %s", hk, hv))
  end

  table.insert(lines, "") -- Empty line separates headers from body in HTTP standard

  local body_str = target_req.body or ""
  if body_str ~= "" then
    local bl = vim.split(body_str, "\r?\n")
    for _, l in ipairs(bl) do
      table.insert(lines, l)
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Execute function from Studio buffer
  local function execute_studio_buffer()
    local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    if #buf_lines == 0 then return end

    local method = "GET"
    local url = ""
    local headers = {}
    local body_lines = {}
    local in_body = false

    for _, line in ipairs(buf_lines) do
      if in_body then
        table.insert(body_lines, line)
      else
        if line:match("^###") or line:match("^//") then
          -- Comment line, ignore
        elseif line:match("^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)%s+(.+)$") then
          method, url = line:match("^(%S+)%s+(.+)$")
        elseif line:match("^%s*$") then
          in_body = true
        else
          local hk, hv = line:match("^([%w_%-]+):%s*(.*)$")
          if hk and hv then
            headers[hk] = hv
          end
        end
      end
    end

    local final_body = #body_lines > 0 and table.concat(body_lines, "\n") or nil

    vim.notify("󰑮 Executing [" .. method .. "] " .. url .. "...", vim.log.levels.INFO, { title = "Postman Studio" })

    runner.execute({
      name = target_req.name or "Studio Request",
      method = method,
      url = url,
      headers = headers,
      body = final_body,
    }, function(resp, err)
      if err then
        vim.notify(err, vim.log.levels.ERROR, { title = "Postman Error" })
      else
        M.current_tab = "response"
        M.render_response(resp)
      end
    end)
  end

  -- Studio buffer keymaps
  vim.keymap.set("n", "<C-s>", execute_studio_buffer, { buffer = bufnr, silent = true, desc = "Send Request" })
  vim.keymap.set("n", "<leader>r", execute_studio_buffer, { buffer = bufnr, silent = true, desc = "Send Request" })
  vim.keymap.set("n", "<C-c><C-c>", execute_studio_buffer, { buffer = bufnr, silent = true, desc = "Send Request" })
  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(winid, true) end, { buffer = bufnr, silent = true, desc = "Close Studio" })

  vim.notify("󰄬 Request Studio opened! Edit payload and press <C-s> or <leader>r to send.", vim.log.levels.INFO, { title = "Postman Studio" })
end

--- Open Telescope picker for collection requests
---@param collection table Parsed collection from parser.lua
function M.open_request_picker(collection)
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    vim.notify("telescope.nvim is required for the Postman request browser", vim.log.levels.ERROR)
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  local items = collection.requests or {}
  if #items == 0 then
    vim.notify("No requests found in this collection", vim.log.levels.WARN, { title = "Postman" })
    return
  end

  pickers.new({}, {
    prompt_title = "🚀 Postman: " .. collection.name .. " (" .. env.active_env_name .. ")",
    finder = finders.new_table({
      results = items,
      entry_maker = function(entry)
        local icon = METHOD_ICONS[entry.method] or ("[" .. entry.method .. "] ")
        local folder_prefix = entry.folder ~= "" and ("📁 " .. entry.folder .. " ❯ ") or ""
        local display_str = string.format("%s %s%s", icon, folder_prefix, entry.name)

        return {
          value = entry,
          display = display_str,
          ordinal = entry.method .. " " .. entry.folder .. " " .. entry.name .. " " .. entry.url,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Request Details & Payload",
      define_preview = function(self, entry)
        local req = entry.value
        local resolved_url = parser.interpolate(req.url, env.env_vars, env.collection_vars, env.runtime_vars)

        local lines = {
          "===========================================================",
          "METHOD:  " .. req.method,
          "NAME:    " .. req.name,
          "FOLDER:  " .. (req.folder ~= "" and req.folder or "(Root)"),
          "URL:     " .. resolved_url,
          "===========================================================",
          "",
          "--- HEADERS ---",
        }

        for hk, hv in pairs(req.headers or {}) do
          local resolved_v = parser.interpolate(hv, env.env_vars, env.collection_vars, env.runtime_vars)
          table.insert(lines, string.format("%s: %s", hk, resolved_v))
        end

        table.insert(lines, "")
        table.insert(lines, "--- PAYLOAD / BODY (" .. string.upper(req.body_mode or "none") .. ") ---")
        if req.body and req.body ~= "" then
          local resolved_body = parser.interpolate(req.body, env.env_vars, env.collection_vars, env.runtime_vars)
          local bl = vim.split(resolved_body, "\r?\n")
          for _, l in ipairs(bl) do table.insert(lines, l) end
        else
          table.insert(lines, "(No body)")
        end

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.bo[self.state.bufnr].filetype = "markdown"
      end,
    }),
    attach_mappings = function(prompt_bufnr, map)
      -- <CR>: Run immediately
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value then
          runner.execute(selection.value, function(resp, err)
            if err then
              vim.notify(err, vim.log.levels.ERROR, { title = "Postman Error" })
            else
              M.current_tab = "response"
              M.render_response(resp)
            end
          end)
        end
      end)

      -- <C-e>: Open in Request Studio to edit payload before sending!
      local function open_studio()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value then
          M.open_request_studio(selection.value)
        end
      end

      map("i", "<C-e>", open_studio)
      map("n", "<C-e>", open_studio)
      map("n", "e", open_studio)

      return true
    end,
  }):find()
end

--- Open Request History Browser in Telescope
function M.open_history_picker()
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    vim.notify("telescope.nvim is required for Postman history", vim.log.levels.ERROR)
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  local history_items = runner.history or {}
  if #history_items == 0 then
    vim.notify("No Postman request history recorded yet. Run a request with <leader>pr first.", vim.log.levels.WARN, { title = "Postman History" })
    return
  end

  pickers.new({}, {
    prompt_title = "📜 Postman Request History (" .. #history_items .. " entries)",
    finder = finders.new_table({
      results = history_items,
      entry_maker = function(entry)
        local code = entry.status_code or 0
        local badge = (code >= 200 and code < 300) and ("󰄬 [" .. code .. " OK]  ")
          or (code >= 300 and code < 400) and ("󰁔 [" .. code .. "]     ")
          or ("󰅚 [" .. code .. " ERR] ")

        local display_str = string.format("%s %s  [%s]  %s  (%s)",
          badge,
          entry.timestamp or "00:00:00",
          entry.method or "GET",
          entry.name or entry.url or "",
          entry.time or "0ms"
        )

        return {
          value = entry,
          display = display_str,
          ordinal = (entry.name or "") .. " " .. (entry.url or "") .. " " .. tostring(entry.status_code),
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Request & Response History",
      define_preview = function(self, entry)
        local item = entry.value
        local req = item.request or {}
        local res = item.response or {}

        local lines = {
          "═══════════════════════════════════════════════════════════",
          "󰅐 TIME:   " .. (item.timestamp or "") .. " (" .. (item.date or "") .. ")",
          "󰑮 METHOD: " .. (item.method or "GET"),
          "🌐 URL:    " .. (item.url or ""),
          "═══════════════════════════════════════════════════════════",
          "",
          "─── OUTGOING REQUEST HEADERS ──────────────────────────────",
        }

        for hk, hv in pairs(req.headers or {}) do
          table.insert(lines, string.format("%s: %s", hk, hv))
        end

        table.insert(lines, "")
        table.insert(lines, "─── OUTGOING REQUEST BODY (PAYLOAD) ───────────────────────")
        local req_b = req.formatted_body or req.body or "(No Body Sent)"
        local r_lines = vim.split(req_b, "\r?\n")
        for _, l in ipairs(r_lines) do table.insert(lines, l) end

        table.insert(lines, "")
        table.insert(lines, "═══════════════════════════════════════════════════════════")
        table.insert(lines, string.format("STATUS: %d (%s)  │  TIME: %s  │  SIZE: %s",
          res.status_code or 0,
          res.status_line or "",
          res.time_duration or item.time or "",
          res.size_formatted or ""
        ))
        table.insert(lines, "═══════════════════════════════════════════════════════════")
        table.insert(lines, "─── RESPONSE BODY ─────────────────────────────────────────")
        local res_b = res.body or "(Empty Response)"
        local b_lines = vim.split(res_b, "\r?\n")
        for _, l in ipairs(b_lines) do table.insert(lines, l) end

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.bo[self.state.bufnr].filetype = "markdown"
      end,
    }),
    attach_mappings = function(prompt_bufnr, map)
      -- <CR>: Open response view
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value and selection.value.response then
          M.current_tab = "response"
          M.render_response(selection.value.response)
        end
      end)

      -- <C-r>: Re-execute this request
      local function rerun_item()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value and selection.value.request then
          local r = selection.value.request
          runner.execute(r, function(new_resp, err)
            if err then
              vim.notify(err, vim.log.levels.ERROR, { title = "Postman Error" })
            else
              M.current_tab = "response"
              M.render_response(new_resp)
            end
          end)
        end
      end

      -- <C-e>: Edit in Request Studio
      local function edit_studio()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value and selection.value.request then
          M.open_request_studio(selection.value.request)
        end
      end

      map("i", "<C-r>", rerun_item)
      map("n", "<C-r>", rerun_item)
      map("i", "<C-e>", edit_studio)
      map("n", "<C-e>", edit_studio)
      map("n", "e", edit_studio)

      return true
    end,
  }):find()
end

--- Interactive variable extraction prompt
---@param json_content string
function M.prompt_extract_variable(json_content)
  vim.ui.input({
    prompt = "Enter JSON field to extract (e.g. token, data.token, user.id): ",
    default = "token",
  }, function(field_path)
    if not field_path or field_path == "" then return end

    vim.ui.input({
      prompt = "Enter variable name to save into environment: ",
      default = field_path:match("[^%.]+$") or "token",
    }, function(var_name)
      if not var_name or var_name == "" then return end

      local ok, val = env.extract_from_json(json_content, field_path, var_name)
      if not ok then
        vim.notify("Failed to extract: " .. tostring(val), vim.log.levels.ERROR, { title = "Postman" })
      else
        vim.notify(string.format("󰄬 Captured variable '{{%s}}' = %s", var_name, tostring(val)), vim.log.levels.INFO, { title = "Postman Env" })
      end
    end)
  end)
end

--- Show floating dialog of all active environment and runtime variables
function M.show_variables()
  local vars = env.get_all_resolved()
  local lines = {
    "󰒋 Active Environment: " .. env.active_env_name,
    "═══════════════════════════════════════════════════════════════════",
  }

  local has_any = false
  for k, v in pairs(vars) do
    has_any = true
    table.insert(lines, string.format("  {{%s}} = %s  [%s]", k, v.value, v.source))
  end

  if not has_any then
    table.insert(lines, "  (No variables currently set)")
  end

  table.insert(lines, "═══════════════════════════════════════════════════════════════════")
  table.insert(lines, "Press 'q' or <Esc> to dismiss")

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"

  local width = math.min(vim.o.columns - 4, 80)
  local height = math.min(vim.o.lines - 4, #lines + 2)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Postman Variables ",
    title_pos = "center",
  })

  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(winid, true) end, { buffer = bufnr })
  vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(winid, true) end, { buffer = bufnr })
end

return M
