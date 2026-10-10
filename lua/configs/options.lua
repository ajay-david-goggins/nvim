vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.numberwidth = 4
vim.opt.wrap = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false

vim.opt.expandtab = true
vim.opt.shiftwidth = 2 -- convert the >> or << with number of space
vim.opt.tabstop = 2 -- number of space character inserted for /t
vim.opt.softtabstop = 2 -- number of space character insteader for <Tab> key
vim.opt.smartindent = true -- enable smart indentation
vim.opt.breakindent = true

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.mouse = "a"
vim.opt.conceallevel = 3
vim.opt.clipboard = "unnamedplus"
vim.opt.fileencoding = "utf-8"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.termguicolors = true
vim.opt.showmode = true
vim.opt.cursorline = true
vim.opt.cursorcolumn = true

-- Fucking execution Timing
vim.opt.timeoutlen = 300 -- for keymap execution time out limit in 0.3 sec
vim.opt.updatetime = 250 -- this is responsible for showing error like git or backup file does
vim.opt.ttimeoutlen = 10 -- this is terminal time out lenth execute <Esc> <Tab> immediately

vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Treesitter-based folding (set up in plugins/treesitter.lua), start unfolded
vim.opt.foldmethod = "expr"
vim.opt.foldlevelstart = 99
vim.opt.foldenable = false

-- Diff options: ignore carriage returns (^M / CRLF) at end of line and whitespace
vim.opt.diffopt:append({ "iwhiteeol", "linematch:60" })

-- Keep existing line endings (dos / CRLF) on open and prevent EditorConfig
-- from marking existing files as modified ([+]) when opening them
local ok_ec, editorconfig = pcall(require, "editorconfig")
if ok_ec and editorconfig.properties then
    local orig_end_of_line = editorconfig.properties.end_of_line
    editorconfig.properties.end_of_line = function(bufnr, val)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        -- If file already exists on disk, preserve its existing detected fileformat
        -- so opening a CRLF file won't mark it modified or silently convert it.
        if fname ~= "" and vim.fn.filereadable(fname) == 1 then
            return
        end
        if orig_end_of_line then
            orig_end_of_line(bufnr, val)
        end
    end
end

-- Normalize Fugitive and scratch diff buffers: if a buffer contains CRLF, set fileformat=dos
-- to prevent raw ^M characters from showing up on screen in diffs
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    callback = function(args)
        local bufnr = args.buf
        local name = vim.api.nvim_buf_get_name(bufnr)
        if name:match("^fugitive://") or name:match("%.git//") or vim.bo[bufnr].buftype == "nofile" then
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 10, false)
            local has_cr = false
            for _, line in ipairs(lines) do
                if line:sub(-1) == "\r" then
                    has_cr = true
                    break
                end
            end
            if has_cr then
                local all_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                for i, line in ipairs(all_lines) do
                    if line:sub(-1) == "\r" then
                        all_lines[i] = line:sub(1, -2)
                    end
                end
                local modifiable = vim.bo[bufnr].modifiable
                vim.bo[bufnr].modifiable = true
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, all_lines)
                vim.bo[bufnr].modifiable = modifiable
                vim.bo[bufnr].modified = false
                vim.bo[bufnr].fileformat = "dos"
            end
        end
    end,
})

vim.cmd([[
    highlight LineNr guifg=#ffffff
    highlight LineNrAbove guifg=#ffffff
    highlight LineNrBelow guifg=#ffffff
    highlight CursorLineNr guifg=#00BFFF gui=bold
]])

-- This makes brackets inside Tailwind classes look like normal text
vim.api.nvim_set_hl(0, "@punctuation.bracket.javascript", { link = "String" })

-- TESTING DIFFERENT GREENS --

-- Option 1: Classic Grass Green (Bright & Readable)
-- vim.api.nvim_set_hl(0, "Comment", { fg = "#7cfc00", italic = true })

-- Option 2: Yellow-Green (Neon style, very high contrast)
-- vim.api.nvim_set_hl(0, "Comment", { fg = "#adff2f", italic = true })

-- Option 3: Forest Green (Darker, easier on the eyes for long sessions)
-- vim.api.nvim_set_hl(0, "Comment", { fg = "#228b22" })

-- Option 4: Seafoam Green (Clean, modern look)
vim.api.nvim_set_hl(0, "Comment", { fg = "#3cb371", bold = true })
