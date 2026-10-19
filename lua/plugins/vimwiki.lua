-- =============================================================================
-- vimwiki.lua · personal wiki / notes, markdown-flavored, kept out of your
-- main projects folder so `conform`'s markdown->prettier formatter and any
-- git repo it runs in doesn't touch it.
-- =============================================================================

-- Hardcoded Wiki Git repository URL & path
local wiki_repo = "https://github.com/ajay-david-goggins/vimwiki_notes.git"
local wiki_dir = vim.fn.expand("~/notes/wiki")

-- Helper: Push notes to remote repo
local function wiki_git_push(commit_msg)
  local msg = commit_msg
  if not msg or msg == "" then
    msg = "wiki sync: " .. os.date("%Y-%m-%d %H:%M:%S")
  end

  vim.notify("Syncing wiki notes to GitHub...", vim.log.levels.INFO, { title = "VimWiki Git" })

  vim.system({ "git", "-C", wiki_dir, "add", "-A" }, { text = true }, function(add_res)
    if add_res.code ~= 0 then
      vim.schedule(function()
        vim.notify("git add failed: " .. (add_res.stderr or ""), vim.log.levels.ERROR, { title = "VimWiki Git" })
      end)
      return
    end

    vim.system({ "git", "-C", wiki_dir, "status", "--porcelain" }, { text = true }, function(status_res)
      local has_changes = vim.trim(status_res.stdout or "") ~= ""

      local function do_push()
        vim.system({ "git", "-C", wiki_dir, "push", "-u", "origin", "main" }, { text = true }, function(push_res)
          vim.schedule(function()
            if push_res.code == 0 then
              vim.notify("󰄬 Wiki pushed to GitHub successfully!", vim.log.levels.INFO, { title = "VimWiki Git" })
            else
              vim.notify("git push failed:\n" .. (push_res.stderr or push_res.stdout or ""), vim.log.levels.ERROR, { title = "VimWiki Git" })
            end
          end)
        end)
      end

      if has_changes then
        vim.system({ "git", "-C", wiki_dir, "commit", "-m", msg }, { text = true }, function(commit_res)
          if commit_res.code ~= 0 then
            vim.schedule(function()
              vim.notify("git commit failed: " .. (commit_res.stderr or ""), vim.log.levels.ERROR, { title = "VimWiki Git" })
            end)
            return
          end
          do_push()
        end)
      else
        do_push()
      end
    end)
  end)
end

-- Helper: Pull notes from remote repo
local function wiki_git_pull()
  vim.notify("Pulling latest wiki notes...", vim.log.levels.INFO, { title = "VimWiki Git" })
  vim.system({ "git", "-C", wiki_dir, "pull", "--rebase", "origin", "main" }, { text = true }, function(res)
    vim.schedule(function()
      if res.code == 0 then
        local out = vim.trim(res.stdout or "Already up to date")
        vim.notify("󰄬 Wiki updated:\n" .. out, vim.log.levels.INFO, { title = "VimWiki Git" })
        vim.cmd("checktime")
      else
        vim.notify("git pull failed:\n" .. (res.stderr or res.stdout or ""), vim.log.levels.ERROR, { title = "VimWiki Git" })
      end
    end)
  end)
end

-- Helper: Check wiki git status + encryption state
local function wiki_git_status()
  vim.system({ "git", "-C", wiki_dir, "status", "-sb" }, { text = true }, function(res)
    vim.schedule(function()
      if res.code == 0 then
        local out = vim.trim(res.stdout or "")
        local is_encrypted = vim.fn.filereadable(wiki_dir .. "/.gitattributes") == 1
        local enc_badge = is_encrypted and "\n🔒 E2E Encryption (.gitattributes active)" or "\n⚠️ Unencrypted (plain text repo)"
        vim.notify((out ~= "" and out or "Clean working tree") .. enc_badge, vim.log.levels.INFO, { title = "VimWiki Git Status" })
      else
        vim.notify("git status failed: " .. (res.stderr or ""), vim.log.levels.ERROR, { title = "VimWiki Git" })
      end
    end)
  end)
end

-- Helper: Open lazygit in wiki directory
local function wiki_lazygit()
  local ok, lazygit = pcall(require, "lazygit")
  if ok and lazygit.lazygit then
    lazygit.lazygit(wiki_dir)
  else
    vim.cmd("terminal cd " .. vim.fn.fnameescape(wiki_dir) .. " && lazygit")
  end
end

-- =============================================================================
-- Smart Todo / Checkbox Toggle & Creator
-- Handles standalone `[ ]`, bulleted `- [ ]`, `* [ ]`, plain text, and visual selections
-- =============================================================================
local function toggle_todo_range(start_line, end_line)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  if #lines == 0 then return end

  -- Analyze the lines in the range
  local has_any_checkbox = false
  local has_unchecked = false
  local has_non_blank = false

  for _, line in ipairs(lines) do
    if not line:match("^%s*$") then
      has_non_blank = true
      local box = line:match("^%s*[-*+]%s+%[([%s%w_%-%.])%]") or line:match("^%s*%[([%s%w_%-%.])%]")
      if box then
        has_any_checkbox = true
        if not box:match("[xX]") then
          has_unchecked = true
        end
      end
    end
  end

  if not has_non_blank then return end

  local is_single_line = (start_line == end_line)
  local new_lines = {}

  for _, line in ipairs(lines) do
    if line:match("^%s*$") then
      table.insert(new_lines, line)
    else
      local new_line = line

      if is_single_line then
        -- 1. Bullet with checkbox: "- [ ]", "* [x]"
        local indent, bullet, box, rest = line:match("^(%s*)([-*+]%s+)%[([%s%w_%-%.])%](.*)$")
        if indent and bullet and box and rest then
          local next_box = box:match("[xX]") and "[ ]" or "[x]"
          new_line = indent .. bullet .. next_box .. rest
        else
          -- 2. Standalone checkbox: "[ ]", "  [x]"
          local indent2, box2, rest2 = line:match("^(%s*)%[([%s%w_%-%.])%](.*)$")
          if indent2 and box2 and rest2 then
            local next_box = box2:match("[xX]") and "[ ]" or "[x]"
            new_line = indent2 .. next_box .. rest2
          else
            -- 3. Bullet without checkbox: "- text", "* text"
            local indent3, bullet3, rest3 = line:match("^(%s*)([-*+]%s+)(.*)$")
            if indent3 and bullet3 and rest3 then
              new_line = indent3 .. bullet3 .. "[ ] " .. rest3
            else
              -- 4. Plain text: "text" -> turn into todo item
              local indent4, rest4 = line:match("^(%s*)(.*)$")
              new_line = indent4 .. "- [ ] " .. rest4
            end
          end
        end
      else
        -- Multi-line (visual selection)
        if not has_any_checkbox then
          -- Convert all selected lines into unchecked checkboxes
          local indent, bullet, rest = line:match("^(%s*)([-*+]%s+)(.*)$")
          if indent and bullet and rest then
            new_line = indent .. bullet .. "[ ] " .. rest
          else
            local indent2, rest2 = line:match("^(%s*)(.*)$")
            new_line = indent2 .. "- [ ] " .. rest2
          end
        else
          -- Checkboxes exist: if any is unchecked, mark all [x]; if all [x], uncheck all to [ ]
          local target_box = has_unchecked and "[x]" or "[ ]"
          local target_prefix = has_unchecked and "[x] " or "[ ] "

          local indent, bullet, box, rest = line:match("^(%s*)([-*+]%s+)%[([%s%w_%-%.])%](.*)$")
          if indent and bullet and box and rest then
            new_line = indent .. bullet .. target_box .. rest
          else
            local indent2, box2, rest2 = line:match("^(%s*)%[([%s%w_%-%.])%](.*)$")
            if indent2 and box2 and rest2 then
              new_line = indent2 .. target_box .. rest2
            else
              local indent3, bullet3, rest3 = line:match("^(%s*)([-*+]%s+)(.*)$")
              if indent3 and bullet3 and rest3 then
                new_line = indent3 .. bullet3 .. target_prefix .. rest3
              else
                local indent4, rest4 = line:match("^(%s*)(.*)$")
                new_line = indent4 .. "- " .. target_prefix .. rest4
              end
            end
          end
        end
      end

      table.insert(new_lines, new_line)
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, new_lines)
end

-- Helper: Create a new todo item below current line and enter insert mode
local function new_todo_item()
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local cur_line = vim.api.nvim_get_current_line()
  local indent = cur_line:match("^(%s*)") or ""
  local bullet = cur_line:match("^%s*([-%*+]%s+)") or "- "
  local new_line = indent .. bullet .. "[ ] "
  vim.api.nvim_buf_set_lines(bufnr, lnum, lnum, false, { new_line })
  vim.api.nvim_win_set_cursor(0, { lnum + 1, #new_line })
  vim.cmd("startinsert!")
end

return {
  "vimwiki/vimwiki",
  init = function()
    -- Set Wiki repo and path in global variables for reference
    vim.g.vimwiki_repo_url = wiki_repo
    vim.g.vimwiki_dir = wiki_dir

    -- Must be set BEFORE the plugin loads — VimWiki reads these on load,
    -- not lazily, so this goes in `init`, not `config`.
    vim.g.vimwiki_list = {
      {
        path = "~/notes/wiki/",
        syntax = "markdown",
        ext = ".md",
      },
    }
    -- Don't hijack every *.md file on your system as a wiki page — only
    -- files actually inside the wiki path above count. Without this,
    -- opening any random README.md would try to activate wiki keymaps.
    vim.g.vimwiki_global = 0

    -- Register user commands for wiki git management
    vim.api.nvim_create_user_command("VimwikiGitPush", function(opts)
      wiki_git_push(opts.args)
    end, { nargs = "?", desc = "Push VimWiki notes to GitHub" })

    vim.api.nvim_create_user_command("VimwikiGitPull", function()
      wiki_git_pull()
    end, { desc = "Pull VimWiki notes from GitHub" })

    vim.api.nvim_create_user_command("VimwikiGitStatus", function()
      wiki_git_status()
    end, { desc = "Show VimWiki git status" })

    vim.api.nvim_create_user_command("VimwikiLazyGit", function()
      wiki_lazygit()
    end, { desc = "Open LazyGit in VimWiki notes directory" })

    -- Register user commands for smart todo management
    vim.api.nvim_create_user_command("VimwikiToggleTodo", function(opts)
      toggle_todo_range(opts.line1, opts.line2)
    end, { range = true, desc = "Toggle todo checkbox on line or visual range" })

    vim.api.nvim_create_user_command("VimwikiNewTodo", function()
      new_todo_item()
    end, { desc = "Insert a new todo checkbox item below current line" })
  end,
  ft = { "vimwiki", "markdown" },
  keys = {
    { "<leader>ww",         "<cmd>VimwikiIndex<CR>",          desc = "[W]iki [W]iki index" },
    { "<leader>wt",         "<cmd>VimwikiTabIndex<CR>",       desc = "[W]iki index in [T]ab" },
    { "<leader>ws",         "<cmd>VimwikiUISelect<CR>",       desc = "[W]iki [S]elect" },
    { "<leader>wi",         "<cmd>VimwikiDiaryIndex<CR>",     desc = "[W]iki d[I]ary" },
    { "<leader>w<leader>w", "<cmd>VimwikiMakeDiaryNote<CR>",  desc = "[W]iki new diary note" },

    -- Smart Checkbox / Todo management (Normal & Visual mode)
    { "<leader>m",          ":VimwikiToggleTodo<CR>", mode = { "n", "v" }, desc = "Toggle todo [ ] ↔ [x] (line/visual)" },
    { "<leader>wn",         "<cmd>VimwikiNewTodo<CR>", desc = "[W]iki [N]ew todo item below" },

    -- Wiki Git repo management
    { "<leader>wgp",        "<cmd>VimwikiGitPush<CR>",        desc = "[W]iki [G]it [P]ush" },
    { "<leader>wgP",        "<cmd>VimwikiGitPull<CR>",        desc = "[W]iki [G]it [P]ull" },
    { "<leader>wgs",        "<cmd>VimwikiGitStatus<CR>",      desc = "[W]iki [G]it [S]tatus" },
    { "<leader>wgl",        "<cmd>VimwikiLazyGit<CR>",        desc = "[W]iki [G]it [L]azyGit" },
  },
}
