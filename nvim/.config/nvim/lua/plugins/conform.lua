-- conform.nvim — formatting on demand.
--
-- <leader>cf runs Prettier (via the fast prettierd daemon, falling back to
-- prettier) for web filetypes, and the language server's own formatter for
-- everything else (Lua via lua_ls, PHP via intelephense).
--
-- Prettier reads config from the nearest .prettierrc walking up from the file,
-- so a project's own config always wins; when none exists it falls back to the
-- global ~/.prettierrc.json (printWidth 120 + industry-standard defaults).
--
-- No format-on-save — it only runs when you press <leader>cf.
return {
  "stevearc/conform.nvim",
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = { "n", "v" },
      desc = "Format buffer / selection",
    },
  },
  opts = {
    formatters_by_ft = {
      javascript = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      css = { "prettierd", "prettier", stop_after_first = true },
      scss = { "prettierd", "prettier", stop_after_first = true },
      less = { "prettierd", "prettier", stop_after_first = true },
      html = { "prettierd", "prettier", stop_after_first = true },
      json = { "prettierd", "prettier", stop_after_first = true },
      jsonc = { "prettierd", "prettier", stop_after_first = true },
      yaml = { "prettierd", "prettier", stop_after_first = true },
      markdown = { "prettierd", "prettier", stop_after_first = true },
      graphql = { "prettierd", "prettier", stop_after_first = true },
      -- Prettier has no Groovy parser; npm-groovy-lint --fix is the only
      -- formatter that understands Jenkinsfiles. It rewrites the file in
      -- place rather than round-tripping stdin, which conform handles.
      groovy = { "npm-groovy-lint" },
    },
    formatters = {
      -- Match the ruleset nvim-lint uses, so formatting never "fixes" a file
      -- into something the linter then complains about.
      ["npm-groovy-lint"] = {
        prepend_args = { "--config", "recommended-jenkinsfile", "--no-insight" },
      },
    },
  },
}
