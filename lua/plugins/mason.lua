-- =============================================================================
-- mason.lua · installs every binary (LSP servers, DAP adapters, formatters).
-- Nothing else — settings live in nvim/lsp/*.lua and plugins/conform.lua.
-- =============================================================================
return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		priority = 100,
		opts = {
			ui = {
				border = "rounded",
				icons = {
					package_installed = "󰄬 ",
					package_pending = "󰔟 ",
					package_uninstalled = "󰅖 ",
				},
			},
		},
	},

	-- mason.nvim itself has no ensure_installed for plain binaries (only
	-- mason-lspconfig does, for servers). This installs the non-LSP tools
	-- conform.nvim shells out to.
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			-- gofumpt intentionally left out -- it's a Go-toolchain binary,
			-- see the "why Go tools stay OUT of mason" note further below.
			-- Install it with `go install mvdan.cc/gofumpt@latest` instead.
			ensure_installed = { "stylua", "prettier" },
			auto_update = false,
		},
	},

	{
		"williamboman/mason-lspconfig.nvim",
		lazy = false,
		dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
		opts = {
			ensure_installed = {
				-- web / general
				"lua_ls",
				"ts_ls",
				"html",
				"cssls",
				"emmet_ls",
				"eslint",
				"clangd",
				"tailwindcss",
				"angularls",
				-- python
				"pyright",
				"ruff",
				-- go: deliberately NOT mason-managed, see note below.
			},
			-- vim.lsp.enable() is called explicitly in configs/lsp.lua instead
			automatic_enable = false,
		},
	},

	-- =====================================================================
	-- Why Go tools stay OUT of mason/mason-lspconfig entirely:
	--
	-- gopls/goimports/gomodifytags/impl are Go-toolchain binaries that mason
	-- builds by shelling out to `go install` under the hood. On a lot of
	-- setups (missing/old `go` on PATH inside the job Neovim spawns,
	-- GOPATH/GOBIN not matching what mason expects, corporate proxies, etc.)
	-- that install silently fails and every Go buffer then spams "gopls not
	-- found" / client exit code 1. That's the "mason not found" problem --
	-- it's a Go-toolchain/mason interaction issue, not something to keep
	-- fighting inside mason.
	--
	-- Fix: install these yourself, once, with the real `go` toolchain, and
	-- let PATH do the rest -- Neovim just needs the binary reachable:
	--
	--   go install golang.org/x/tools/gopls@latest
	--   go install golang.org/x/tools/cmd/goimports@latest
	--   go install mvdan.cc/gofumpt@latest
	--   go install github.com/fatih/gomodifytags@latest
	--   go install github.com/josharian/impl@latest
	--
	-- Then make sure $(go env GOPATH)/bin (usually ~/go/bin) is on your shell
	-- PATH. configs/lsp.lua checks vim.fn.executable("gopls") before enabling
	-- the server, so if you haven't done this yet you get one clean warning
	-- instead of repeated connection errors, and every other server keeps
	-- working normally.
	-- =====================================================================

	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = { "williamboman/mason.nvim", "mfussenegger/nvim-dap" },
		opts = {
			ensure_installed = { "java-debug-adapter", "java-test", "debugpy", "delve" },
			automatic_installation = true,
			handlers = {},
		},
	},
}
