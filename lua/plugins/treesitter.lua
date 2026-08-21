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

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				local ok = pcall(vim.treesitter.start, args.buf)
				if not ok then
					return
				end
				vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end,
		})
	end,
}
