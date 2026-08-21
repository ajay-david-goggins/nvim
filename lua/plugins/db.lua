-- =============================================================================
-- db.lua · Neovim 0.13+ · vim-dadbod + dadbod-ui + dadbod-completion
-- =============================================================================
--
-- ROOT CAUSE OF THE ORIGINAL BUG:
--
-- `cmd = {...}` was the ONLY lazy-load trigger, and every keymap was defined
-- inside config(). Lazy.nvim will not run config() until one of the `cmd`
-- names is invoked — but the only way to invoke :DBUIToggle was the keymap,
-- which didn't exist yet because config() hadn't run.
--
-- Chicken-and-egg:
--
--   [Neovim starts]
--        ↓
--   plugin NOT loaded
--        ↓
--   <leader>du not registered
--        ↓
--   keypress falls through to native Neovim
--        ↓
--   "de" becomes delete-to-end-of-word
--
-- PERMANENT FIX:
--
-- `keys = {...}` tells lazy.nvim to register the key sequences BEFORE the
-- plugin loads. Pressing the key then causes lazy.nvim to load the plugin,
-- run config(), and replay the keypress.
--
-- `ft = {...}` also makes sure the plugin loads when entering SQL buffers,
-- even if no global DBUI key was pressed first.
--
-- =============================================================================
-- NAMESPACE
-- =============================================================================
--
-- Global DBUI mappings:
--
--   <leader>du  → DBUI Toggle
--   <leader>dc  → Add Connection
--   <leader>df  → Find Buffer
--   <leader>dr  → Rename Buffer
--   <leader>dq  → Last Query Info
--
-- SQL-buffer mappings:
--
--   <leader>de  → Execute query / selection
--   <leader>ds  → Save query
--   <leader>dd  → Edit bind parameters
--
-- Note:
-- <leader>d already has other mappings such as:
--   do / dp / dn / dq → diagnostics
--   dt / dT           → jdtls tests
--
-- These do NOT conflict with <leader>db* because the DB mappings branch
-- from <leader>d followed by their specific key.
-- =============================================================================

return {
	-- =========================================================================
	-- vim-dadbod
	-- =========================================================================
	{
		"tpope/vim-dadbod",
		lazy = true,
	},

	-- =========================================================================
	-- vim-dadbod-ui
	-- =========================================================================
	{
		"kristijanhusak/vim-dadbod-ui",

		dependencies = {
			"tpope/vim-dadbod",
		},

		-- Commands that can trigger lazy-loading.
		cmd = {
			"DBUI",
			"DBUIToggle",
			"DBUIAddConnection",
			"DBUIFindBuffer",
			"DBUIRenameBuffer",
			"DBUILastQueryInfo",
		},

		-- Load when entering DB/query buffers.
		ft = {
			"sql",
			"mysql",
			"plsql",
		},

		-- =====================================================================
		-- GLOBAL LAZY-LOAD KEYMAPS
		-- =====================================================================
		--
		-- These mappings are registered by lazy.nvim BEFORE the plugin loads.
		-- This prevents the original <leader>de "delete character/word" problem.
		--
		keys = {
			{
			    "<leader>dbu",
			    "<cmd>DBUIToggle<CR>",
			    desc = "[D]ata[B]ase [U]I Toggle",
			},

			{
				"<leader>dc",
				"<cmd>DBUIAddConnection<CR>",
				desc = "[D]atabase [C]onnection Add",
			},

			{
				"<leader>df",
				"<cmd>DBUIFindBuffer<CR>",
				desc = "[D]atabase [F]ind Buffer",
			},

			{
				"<leader>dr",
				"<cmd>DBUIRenameBuffer<CR>",
				desc = "[D]atabase [R]ename Buffer",
			},

			{
				"<leader>dq",
				"<cmd>DBUILastQueryInfo<CR>",
				desc = "[D]atabase Last [Q]uery Info",
			},
		},

		-- =====================================================================
		-- INIT
		-- =====================================================================
		--
		-- dadbod-ui reads these globals during plugin startup, so they belong
		-- in init(), NOT config().
		--
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
			vim.g.db_ui_show_help = 0

			vim.g.db_ui_win_position = "left"
			vim.g.db_ui_winwidth = 35

			vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui_queries"

			-- Do NOT automatically execute queries when saving.
			vim.g.db_ui_execute_on_save = 0
		end,

		-- =====================================================================
		-- CONFIG
		-- =====================================================================
		config = function()
			local map = vim.keymap.set

			-- Filetypes where DB buffer mappings should exist.
			local db_filetypes = {
				"sql",
				"mysql",
				"plsql",
				"dbout",
				"dbui",
			}

			-- =================================================================
			-- Apply DB buffer-local mappings
			-- =================================================================
			local function apply_db_buffer_keymaps(buf)
				local opts = function(desc)
					return {
						buffer = buf,
						silent = true,
						desc = desc,
					}
				end

				-- -------------------------------------------------------------
				-- Execute query
				-- -------------------------------------------------------------
				--
				-- Normal mode:
				-- Execute the entire buffer.
				--
				-- Visual mode:
				-- Execute only the selected SQL.
				--
				-- Direct :DB commands are intentionally used instead of:
				--
				--   <Plug>(DBUI_ExecuteQuery)
				--
				-- because the direct command is more reliable with lazy-loaded
				-- plugins and avoids <Plug> mapping resolution issues.
				--
				map("n", "<leader>de", "<cmd>%DB<CR>", opts("[D]atabase [E]xecute query"))

				map("v", "<leader>de", ":DB<CR>", opts("[D]atabase [E]xecute selection"))

				-- -------------------------------------------------------------
				-- Save query
				-- -------------------------------------------------------------
				map("n", "<leader>ds", "<Plug>(DBUI_SaveQuery)", opts("[D]atabase [S]ave query"))

				-- -------------------------------------------------------------
				-- Edit bind parameters
				-- -------------------------------------------------------------
				map("n", "<leader>dd", "<Plug>(DBUI_EditBindParameters)", opts("[D]atabase e[D]it bind parameters"))
			end

			-- =================================================================
			-- FileType autocmd
			-- =================================================================
			--
			-- This handles every FUTURE SQL/DB buffer.
			--
			vim.api.nvim_create_autocmd("FileType", {
				pattern = db_filetypes,

				group = vim.api.nvim_create_augroup("UserDadbodBuffer", { clear = true }),

				callback = function(args)
					apply_db_buffer_keymaps(args.buf)
				end,
			})

			-- =================================================================
			-- CURRENT BUFFER RACE-CONDITION FIX
			-- =================================================================
			--
			-- Important:
			--
			-- If opening an SQL file itself caused lazy.nvim to load this
			-- plugin through `ft = {...}`, the FileType event may have already
			-- happened BEFORE the autocmd above was created.
			--
			-- In that case the current buffer would miss:
			--
			--   <leader>de
			--   <leader>ds
			--   <leader>dd
			--
			-- So explicitly handle the current buffer once.
			--
			local cur_buf = vim.api.nvim_get_current_buf()

			if vim.tbl_contains(db_filetypes, vim.bo[cur_buf].filetype) then
				apply_db_buffer_keymaps(cur_buf)
			end

			-- =================================================================
			-- SANITY CHECKS
			-- =================================================================
			--
			-- Run these inside an SQL buffer if something looks wrong:
			--
			--   :set filetype?
			--
			-- Should show:
			--
			--   filetype=sql
			--
			-- or mysql/plsql.
			--
			-- Check mapping:
			--
			--   :map <leader>de
			--
			-- See where mapping came from:
			--
			--   :verbose map <leader>de
			--
			-- Check all DB mappings:
			--
			--   :map <leader>d
			--
		end,
	},

	-- =========================================================================
	-- vim-dadbod-completion
	-- =========================================================================
	-- No config() needed anymore: it's wired as a blink.cmp source scoped to
	-- sql/mysql/plsql filetypes in plugins/completion.lua
	-- (sources.per_filetype + sources.providers.dadbod). blink resolves
	-- providers lazily per-buffer, so the old FileType autocmd that used to
	-- call cmp.setup.buffer() by hand is gone.
	{
		"kristijanhusak/vim-dadbod-completion",
		ft = { "sql", "mysql", "plsql" },
		dependencies = { "tpope/vim-dadbod" },
	},
}

-- =============================================================================
-- KEYBIND CHEATSHEET
-- =============================================================================
--
-- GLOBAL
-- ---------------------------------------------------------------------------
--
-- <leader>du   [D]atabase [U]I Toggle
-- <leader>dc   [D]atabase [C]onnection Add
-- <leader>df   [D]atabase [F]ind Buffer
-- <leader>dr   [D]atabase [R]ename Buffer
-- <leader>dq   [D]atabase Last [Q]uery Info
--
--
-- SQL / MYSQL / PLSQL / DBOUT / DBUI BUFFERS
-- ---------------------------------------------------------------------------
--
-- <leader>de   [D]atabase [E]xecute query
--              Normal mode → entire buffer
--              Visual mode → selected SQL
--
-- <leader>ds   [D]atabase [S]ave query
--
-- <leader>dd   [D]atabase e[D]it bind parameters
--
-- =============================================================================
-- IMPORTANT:
--
-- The actual mappings are:
--
--   <leader>du
--   <leader>dc
--   <leader>df
--   <leader>dr
--   <leader>dq
--   <leader>de
--   <leader>ds
--   <leader>dd
--
-- NOT:
--
--   <leader>dbu
--   <leader>dbc
--   <leader>dbe
--
-- The latter would require an extra `b` in the key sequence.
-- =============================================================================
