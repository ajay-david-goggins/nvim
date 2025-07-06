-- ~/.config/nvim/lua/plugins/eslint.lua
return {
    name = "eslint-setup",
    dir = vim.fn.stdpath("config"), -- point to a valid folder (to silence lazy.nvim)

    lazy = true,
    init = function()
        vim.keymap.set("n", "<leader>ce", function()
            local config_path = vim.fn.getcwd() .. "/eslint.config.mjs"

            if vim.fn.filereadable(config_path) == 1 then
                vim.notify("eslint.config.mjs already exists ✋", vim.log.levels.WARN)
                return
            end

            -- Write the config
            local eslint_config = [[
import path from "node:path";
import { fileURLToPath } from "node:url";

import js from "@eslint/js";
import parser from "@typescript-eslint/parser";
import plugin from "@typescript-eslint/eslint-plugin";
import globals from "globals";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default [
  js.configs.recommended,
  {
    files: ["**/*.ts"],
    languageOptions: {
      parser,
      parserOptions: {
        project: "./tsconfig.app.json",
        tsconfigRootDir: __dirname,
      },
      globals: {
        ...globals.browser,
        ...globals.es2021,
        console: true,
        window: true,
        document: true,
      },
    },
    plugins: {
      "@typescript-eslint": plugin,
    },
    rules: {
      "no-unused-vars": "warn",
      "no-undef": "error",
      "no-console": "off",
      "@typescript-eslint/no-explicit-any": "warn",
    },
  },
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: {
        ...globals.browser,
        ...globals.es2021,
        console: true,
        window: true,
        document: true,
      },
    },
    rules: {
      "no-unused-vars": "warn",
      "no-undef": "error",
      "no-console": "off",
    },
  },
  {
    files: ["**/*.html"],
    languageOptions: {
      parser: null,
    },
    rules: {},
  },
];
]]

            -- Write to eslint.config.mjs
            local file = io.open(config_path, "w")
            file:write(eslint_config)
            file:close()
            vim.notify("✅ eslint.config.mjs created!", vim.log.levels.INFO)

            -- Auto install npm dependencies
            vim.fn.system({
                "npm", "install", "--save-dev",
                "eslint",
                "@eslint/js",
                "@typescript-eslint/eslint-plugin",
                "@typescript-eslint/parser",
                "globals"
            })
            vim.notify("📦 ESLint dependencies installed", vim.log.levels.INFO)
        end, { desc = "[C]reate [E]SLint Config" })
    end,
}

