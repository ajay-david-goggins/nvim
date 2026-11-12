local K = vim.keymap.set
vim.g.leader = " "
vim.g.mapleader = " "

K("n", "<Esc>", "<CMD>nohlsearch<CR>", { desc = "Remove search highlights" })
K("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

K("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
K("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
K("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
K("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

K("n", "<leader>zi", "<C-w>_<C-w>|", { desc = "[Z]oom [i]n current buffer" })
K("n", "<leader>zo", "<C-w>=", { desc = "[Z]oom [O]ut current buffer" })

K("n", "<leader>wv", "<CMD>vsplit<CR>", { desc = "[W]indow Split [V]ertically" })
K("n", "<leader>wh", "<CMD>split<CR>", { desc = "[W]indow Split [H]orizontally" })

-- Moving Line  [ N + V ]
K("n", "<A-j>", "<CMD>m .+1<CR>==", { desc = "Move one line down" })
K("n", "<A-k>", "<CMD>m .-2<CR>==", { desc = "Move one line up" })

K("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move one line down" })

K("n", "<A-l>", ">>", { desc = "Indent right" })
K("n", "<A-h>", "<<", { desc = "Indent right" })
K("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move one line up" })

K("v", "<A-l>", ">gv", { desc = "Indent right" })
K("v", "<A-h>", "<gv", { desc = "Indent left" })

-- (diagnostic float lives at <leader>do, configs/lsp.lua — was duplicated
-- here as <leader>cm; removed to match the "no redundant mappings" rule)

-- genenral
K("n", "<leader>q", "<CMD>q<CR>", { desc = "[Q]uit for single file" })
K("n", "<leader>qa", "<CMD>qa<CR>", { desc = "[Q]uit [A]ll files" })

K("n", "<A-L>", ":vertical resize +2<CR>", { desc = "Make window left" })
K("n", "<A-J>", ":resize +2<CR>", { desc = "Make window down" })
K("n", "<A-K>", ":resize -2<CR>", { desc = "Make window up" })
K("n", "<A-H>", ":vertical resize -2<CR>", { desc = "Make window right" })

K("n", "<leader>tt", ":belowright split | resize 10 | terminal<CR>", { desc = "[T]iny [T]erminal", silent = true })

-- Toggle background transparency (Transparent UI <-> Solid Dracula)
K("n", "<leader>tb", function()
    local ok, transparent = pcall(require, "transparent")
    if ok then
        transparent.toggle()
        if vim.g.transparent_enabled then
            vim.notify("✨ Background: Transparent (Wallpaper visible)", vim.log.levels.INFO, { title = "Neovim Transparency" })
        else
            vim.notify("🎨 Background: Solid (Dracula default)", vim.log.levels.INFO, { title = "Neovim Transparency" })
        end
    else
        vim.notify("transparent.nvim not loaded", vim.log.levels.WARN)
    end
end, { desc = "[T]oggle [B]ackground transparency" })

-- Convenience alias: <leader>tr for Toggle Transparency
K("n", "<leader>tr", "<leader>tb", { remap = true, desc = "[T]oggle T[r]ansparency" })


-- wrap text
K("n", "<A-z>", function()
    vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle word wrap for current file", silent = true }) -- local file

K("n", "<A-Z>", function()
    vim.opt.wrap = not vim.opt.wrap:get()
end, { desc = "Toggle word wrap for every file", silent = true }) -- every file

-- Code Folding Keymaps:
-- In expr/treesitter mode, zf normally errors with E350.
-- Normal mode: zf toggles the fold under cursor (like za) without error.
-- Visual mode: zf creates a manual fold for the selection without error.
K("n", "zf", function()
    if vim.fn.foldlevel(".") > 0 then
        vim.cmd("normal! za")
    else
        local ok = pcall(vim.cmd, "normal! zc")
        if not ok then
            vim.notify("No fold under cursor (select lines in visual mode and press zf to fold)", vim.log.levels.INFO)
        end
    end
end, { desc = "Toggle fold under cursor (no E350)" })

K("v", "zf", function()
    vim.opt_local.foldmethod = "manual"
    vim.cmd("normal! zf")
end, { desc = "Create manual fold for visual selection" })


K("n", "<leader>a", "ggVG", { desc = "Select [A]ll (whole buffer)" }) -- desc was mislabeled ("Make window narrower")

-- auto save
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
    pattern = "*",
    callback = function()
        if vim.bo.modified and vim.bo.modifiable then
            vim.cmd("silent! write")
        end
    end,
})

-- =============================================================================
-- Formatting Helpers (Conform / LSP with accurate range detection)
-- =============================================================================
local function get_visual_selection_range()
    local mode = vim.fn.mode()
    local is_visual = (mode == "v" or mode == "V" or mode == "\22")
    local start_row, start_col, end_row, end_col

    if is_visual then
        local vpos = vim.fn.getpos("v")
        local dotpos = vim.fn.getpos(".")
        start_row = vpos[2]
        start_col = vpos[3]
        end_row = dotpos[2]
        end_col = dotpos[3]

        if start_row > end_row or (start_row == end_row and start_col > end_col) then
            start_row, end_row = end_row, start_row
            start_col, end_col = end_col, start_col
        end

        if mode == "V" then
            start_col = 0
            local end_line = vim.api.nvim_buf_get_lines(0, end_row - 1, end_row, true)[1] or ""
            end_col = #end_line
        elseif mode == "v" then
            start_col = math.max(0, start_col - 1)
            local end_line = vim.api.nvim_buf_get_lines(0, end_row - 1, end_row, true)[1] or ""
            end_col = math.min(#end_line, end_col)
        else
            -- Block mode (<C-v>)
            start_col = 0
            local end_line = vim.api.nvim_buf_get_lines(0, end_row - 1, end_row, true)[1] or ""
            end_col = #end_line
        end
    else
        local start_mark = vim.api.nvim_buf_get_mark(0, "<")
        local end_mark = vim.api.nvim_buf_get_mark(0, ">")
        if start_mark[1] == 0 or end_mark[1] == 0 then
            return nil
        end
        start_row = math.min(start_mark[1], end_mark[1])
        end_row = math.max(start_mark[1], end_mark[1])
        start_col = 0
        local end_line = vim.api.nvim_buf_get_lines(0, end_row - 1, end_row, true)[1] or ""
        end_col = #end_line
    end

    return {
        start = { start_row, start_col },
        ["end"] = { end_row, end_col },
    }
end

local function format_whole_file()
    local ok, conform = pcall(require, "conform")
    if ok then
        conform.format({ async = false, timeout_ms = 2000, lsp_format = "fallback" }, function(err)
            if err then
                vim.notify("Format error: " .. tostring(err), vim.log.levels.WARN)
            else
                vim.notify("Code Formatted! ✨", vim.log.levels.INFO)
            end
        end)
    else
        vim.lsp.buf.format({ async = false })
        vim.notify("Code Formatted! ✨", vim.log.levels.INFO)
    end
end

local function format_selected_code()
    local range = get_visual_selection_range()
    -- Exit visual mode back to normal mode immediately to avoid race conditions
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

    if not range then
        vim.notify("No visual selection to format.", vim.log.levels.WARN)
        return
    end

    local start_row = range.start[1]
    local end_row = range["end"][1]

    local ok, conform = pcall(require, "conform")
    if ok then
        conform.format({ bufnr = 0, range = range, async = false, timeout_ms = 2000, lsp_format = "fallback" }, function(err)
            if err then
                vim.notify("Format selection error: " .. tostring(err), vim.log.levels.WARN)
            else
                vim.notify(string.format("Formatted selected code (lines %d-%d)! 🎯", start_row, end_row), vim.log.levels.INFO)
            end
        end)
    else
        vim.lsp.buf.format({
            bufnr = 0,
            range = range,
            async = false,
        })
        vim.notify(string.format("Formatted selected code (lines %d-%d)! 🎯", start_row, end_row), vim.log.levels.INFO)
    end
end

-- Manual Formatting Keymap: Whole File
vim.keymap.set("n", "<leader>fwc", format_whole_file, { desc = "[F]ormat [W]hole [C]ode with Prettier/LSP" })
vim.keymap.set("n", "<leader>cf", format_whole_file, { desc = "󰉿  [C]ode [F]ormat Buffer" })

-- Format ONLY the selection (Visual Mode)
vim.keymap.set("v", "<leader>fsc", format_selected_code, { desc = "[F]ormat [S]elected [C]ode only" })
vim.keymap.set("v", "<leader>cf", format_selected_code, { desc = "󰉿  [C]ode [F]ormat Selection" })

-- Standard LSP navigation fallbacks (gd, <C-]>, K)
K("n", "gd", function()
    if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
        vim.lsp.buf.definition()
    else
        vim.cmd("normal! gd")
    end
end, { desc = "Go to Definition" })

K("n", "<C-]>", function()
    if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
        vim.lsp.buf.definition()
    else
        local ok, _ = pcall(vim.cmd, "tag " .. vim.fn.expand("<cword>"))
        if not ok then
            vim.notify("No LSP attached and no tags file found.", vim.log.levels.WARN)
        end
    end
end, { desc = "Go to Definition / Tag" })

