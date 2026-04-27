-- ~/.config/nvim/lua/lsp/servers.lua
local M  = {}
local cap = require("lsp.utils").capabilities()

-- C / C++  (sudo apt install clangd)
M.clangd = {
    capabilities = cap,
    cmd = { "clangd", "--background-index", "--clang-tidy" },
}

-- JS / TS  (sudo npm install -g typescript typescript-language-server)
M.ts_ls = {
    capabilities = cap,
    settings = {
        typescript = {
            inlayHints = {
                includeInlayParameterNameHints          = "literals",
                includeInlayFunctionLikeReturnTypeHints = true,
            },
        },
        javascript = {
            inlayHints = {
                includeInlayParameterNameHints          = "literals",
                includeInlayFunctionLikeReturnTypeHints = true,
            },
        },
    },
}

-- ESLint  (sudo npm install -g vscode-langservers-extracted)
M.eslint = {
    capabilities = cap,
    settings = {
        codeActionOnSave = { enable = true, mode = "all" },
    },
}

-- HTML  (sudo npm install -g vscode-langservers-extracted)
M.html = { capabilities = cap }

-- CSS  (sudo npm install -g vscode-langservers-extracted)
M.cssls = { capabilities = cap }

-- Tailwind  (sudo npm install -g @tailwindcss/language-server)
M.tailwindcss = { capabilities = cap }

-- Lua (for editing your config)
M.lua_ls = {
    capabilities = cap,
    settings = {
        Lua = {
            runtime     = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace   = {
                library         = { vim.env.VIMRUNTIME },
                checkThirdParty = false,
            },
            telemetry = { enable = false },
        },
    },
}

return M
