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
		local langs = {
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
		}

		local ok_configs, configs = pcall(require, "nvim-treesitter.configs")
		if ok_configs then
			configs.setup({
				ensure_installed = langs,
				sync_install = false,
				auto_install = true,
				highlight = {
					enable = true,
					disable = function(lang, buf)
						local max_filesize = 100 * 1024 -- 100 KB
						local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
						if ok and stats and stats.size > max_filesize then
							return true
						end
					end,
				},
				indent = { enable = true },
			})
		else
			local ok_ts, ts = pcall(require, "nvim-treesitter")
			if ok_ts then
				if ts.setup then pcall(ts.setup) end
				if ts.install then pcall(ts.install, langs) end
			end
		end

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				local ok = pcall(vim.treesitter.start, args.buf)
				if not ok then
					return
				end
				vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				local ok_ts = pcall(require, "nvim-treesitter")
				if ok_ts and package.loaded["nvim-treesitter"] and require("nvim-treesitter").indentexpr then
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
