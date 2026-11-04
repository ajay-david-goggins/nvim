-- =============================================================================
-- treesitter.lua · nvim-treesitter `main` branch (the 2025+ rewrite: no more
-- `configs.setup`, install()/update() replace :TSInstall, and highlighting
-- is enabled per-buffer via vim.treesitter.start()).
-- =============================================================================
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	dependencies = { "windwp/nvim-ts-autotag" },
	config = function()
		require("nvim-treesitter").setup()

		require("nvim-treesitter").install({
			"lua",
			"vim",
			"vimdoc",
			"query",
			"javascript",
			"typescript",
			"tsx",
			"html",
			"css",
			"json",
			"python",
			"go",
			"gomod",
			"gosum",
			"gowork",
			"c",
			"cpp",
			"rust",
			"java",
			"markdown",
			"markdown_inline",
			"bash",
			"yaml",
			"toml",
			"regex",
		})

		-- Method/function-level fold queries:
		-- Keeps classes/types open, collapses method and function bodies on open.
		local custom_folds = {
			python = [[
(function_definition) @fold
[
  (import_statement)
  (import_from_statement)
]+ @fold
]],
			go = [[
(function_declaration) @fold
(method_declaration) @fold
[ (import_declaration) ]+ @fold
]],
			java = [[
(method_declaration) @fold
(constructor_declaration) @fold
[ (import_declaration) ]+ @fold
]],
			javascript = [[
(function_declaration) @fold
(method_definition) @fold
[ (import_statement) ]+ @fold
]],
			typescript = [[
(function_declaration) @fold
(method_definition) @fold
[ (import_statement) ]+ @fold
]],
			tsx = [[
(function_declaration) @fold
(method_definition) @fold
[ (import_statement) ]+ @fold
]],
			rust = [[
(function_item) @fold
[ (use_declaration) ]+ @fold
]],
			c = "(function_definition) @fold",
			cpp = "(function_definition) @fold",
			lua = "(function_declaration) @fold",
		}

		for lang, q in pairs(custom_folds) do
			pcall(vim.treesitter.query.set, lang, "folds", q)
		end

		local code_filetypes = {
			python = true,
			go = true,
			java = true,
			javascript = true,
			typescript = true,
			typescriptreact = true,
			javascriptreact = true,
			rust = true,
			c = true,
			cpp = true,
			lua = true,
		}

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				local ok = pcall(vim.treesitter.start, args.buf)
				if not ok then
					return
				end
				vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

				local ft = args.match ~= "" and args.match or vim.bo[args.buf].filetype
				if code_filetypes[ft] then
					vim.wo.foldmethod = "expr"
					vim.wo.foldenable = true
					vim.wo.foldlevel = 0
				end
			end,
		})
	end,
}
