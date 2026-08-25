-- =============================================================================
-- lang/java.lua · jdtls doesn't fit the native lsp/*.lua model (it needs a
-- per-project workspace dir computed at attach time), so it stays plugin-
-- driven via nvim-jdtls's own start_or_attach, same as before.
-- =============================================================================
return {
  "mfussenegger/nvim-jdtls",
  dependencies = { "mfussenegger/nvim-dap" },
  ft = { "java" },
  config = function()
    local home = os.getenv("HOME")
    local mason_pkg = home .. "/.local/share/nvim/mason/packages"
    local data_dir = home .. "/.local/share/nvim/jdtls"
    local project = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
    local workspace = data_dir .. "/workspace/" .. project

    local bundles = {}
    local debug_jar = vim.fn.glob(mason_pkg .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar")
    if debug_jar ~= "" then vim.list_extend(bundles, { debug_jar }) end
    vim.list_extend(bundles, vim.split(
      vim.fn.glob(mason_pkg .. "/java-test/extension/server/*.jar"), "\n", { trimempty = true }
    ))

    local launcher_matches = vim.fn.split(vim.fn.glob(mason_pkg .. "/jdtls/plugins/org.eclipse.equinox.launcher_*.jar"), "\n")
    local launcher_jar = launcher_matches[1]
    if not launcher_jar then
      vim.notify("JDTLS launcher JAR missing! Run :MasonInstall jdtls", vim.log.levels.ERROR)
      return
    end

    local has_blink, blink = pcall(require, "blink.cmp")
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    if has_blink then capabilities = blink.get_lsp_capabilities(capabilities) end

    require("jdtls").start_or_attach({
      cmd = {
        "java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.level=ALL", "-Xmx2g",
        "--add-modules=ALL-SYSTEM",
        "--add-opens", "java.base/java.util=ALL-UNNAMED",
        "--add-opens", "java.base/java.lang=ALL-UNNAMED",
        "-jar", launcher_jar,
        "-configuration", mason_pkg .. "/jdtls/config_linux",
        "-data", workspace,
      },
      root_dir = require("jdtls.setup").find_root({ "gradlew", "mvnw", ".git", "pom.xml", "build.gradle" }),
      settings = {
        java = {
          eclipse = { downloadSources = true },
          maven = { downloadSources = true },
          inlayHints = { parameterNames = { enabled = "all" } },
          signatureHelp = { enabled = true },
          referencesCodeLens = { enabled = true },
          implementationsCodeLens = { enabled = true },
        },
      },
      init_options = {
        bundles = bundles,
        extendedClientCapabilities = require("jdtls").extendedClientCapabilities,
      },
      capabilities = capabilities,
      on_attach = function(_, bufnr)
        require("jdtls").setup_dap({ hotcodereplace = "auto" })
        require("jdtls.dap").setup_dap_main_class_configs()
        local o = { buffer = bufnr, silent = true }
        local jdtls = require("jdtls")
        vim.keymap.set("n", "<leader>jo", jdtls.organize_imports, vim.tbl_extend("force", o, { desc = "󰶮  Java Organize Imports" }))
        vim.keymap.set("n", "<leader>jv", jdtls.extract_variable, vim.tbl_extend("force", o, { desc = "󰫙  Java Extract Variable" }))
        vim.keymap.set("n", "<leader>jc", jdtls.extract_constant, vim.tbl_extend("force", o, { desc = "󰏿  Java Extract Constant" }))
        vim.keymap.set("v", "<leader>jm", [[<ESC><CMD>lua require("jdtls").extract_method(true)<CR>]], vim.tbl_extend("force", o, { desc = "󰊕  Java Extract Method" }))
        -- Test runners keep their own dt/dT letters, same convention as Go.
        vim.keymap.set("n", "<leader>dt", jdtls.test_nearest_method, vim.tbl_extend("force", o, { desc = "󰙨  [D]ap [T]est method" }))
        vim.keymap.set("n", "<leader>dT", jdtls.test_class, vim.tbl_extend("force", o, { desc = "󰙨  [D]ap [T]est class" }))
        --
        -- Unified DAP scheme — identical letters across every language,
        -- see lang/python.lua for the shared-namespace rationale.
        -- local ok_dap, dap = pcall(require, "dap")
        -- if ok_dap then
        --   vim.keymap.set("n", "<leader>db",  dap.toggle_breakpoint, vim.tbl_extend("force", o, { desc = "  [D]ap [B]reakpoint toggle" }))
        --   vim.keymap.set("n", "<leader>dc",  dap.continue,          vim.tbl_extend("force", o, { desc = "  [D]ap [C]ontinue" }))
        --   vim.keymap.set("n", "<leader>dso", dap.step_over,         vim.tbl_extend("force", o, { desc = "  [D]ap [S]tep [O]ver" }))
        --   vim.keymap.set("n", "<leader>dsi", dap.step_into,         vim.tbl_extend("force", o, { desc = "  [D]ap [S]tep [I]nto" }))
        --   vim.keymap.set("n", "<leader>dsO", dap.step_out,          vim.tbl_extend("force", o, { desc = "  [D]ap [S]tep [O]ut" }))
        --   vim.keymap.set("n", "<leader>dr",  dap.repl.open,         vim.tbl_extend("force", o, { desc = "  [D]ap [R]epl open" }))
        --   vim.keymap.set("n", "<leader>dl",  dap.run_last,          vim.tbl_extend("force", o, { desc = "  [D]ap Run [L]ast" }))
        --   vim.keymap.set("n", "<leader>dq",  dap.terminate,         vim.tbl_extend("force", o, { desc = "  [D]ap [Q]uit/terminate" }))
        -- end
      end,
    })
  end,
}
