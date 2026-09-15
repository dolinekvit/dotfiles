-- nvim-lint — diagnostics from tools that aren't language servers.
--
-- Currently only Groovy/Jenkinsfile. npm-groovy-lint wraps CodeNarc and is the
-- one linter that actually understands Jenkins pipelines.
--
-- NOTE: groovyls was deliberately skipped. It needs a system JDK and is a
-- *generic* Groovy server — it doesn't know `pipeline`, `stage`, `agent` or
-- `sh`, so it reports valid declarative pipelines as errors. npm-groovy-lint
-- manages its own JRE under ~/.java-caller, so nothing needs to be on $PATH.
return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      groovy = { "npm-groovy-lint" },
    }

    -- The bundled linter runs CodeNarc's generic Groovy ruleset, which flags
    -- every Jenkinsfile with "class should be marked @CompileStatic" and
    -- similar noise. `recommended-jenkinsfile` is the pipeline ruleset: it
    -- leaves a valid pipeline clean and still catches parse errors.
    local ngl = lint.linters["npm-groovy-lint"]
    ngl.args = {
      "--config", "recommended-jenkinsfile",
      "--no-insight", -- don't report anonymous usage stats upstream
      "-o", "json",
      "-",            -- read the buffer from stdin
    }

    -- mason-lspconfig's ensure_installed only covers language servers, so this
    -- non-LSP tool is pulled in by hand the first time it's missing.
    local ok, registry = pcall(require, "mason-registry")
    if ok then
      registry.refresh(function()
        local found, pkg = pcall(registry.get_package, "npm-groovy-lint")
        if found and not pkg:is_installed() then
          pkg:install()
        end
      end)
    end

    -- On write and on open only. Each run spawns a JVM and takes a second or
    -- two, so linting on every InsertLeave would be more annoying than useful.
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
      group = vim.api.nvim_create_augroup("user_nvim_lint", { clear = true }),
      desc = "Run nvim-lint for filetypes that have a linter configured",
      callback = function()
        lint.try_lint()
      end,
    })

    vim.keymap.set("n", "<leader>cl", function()
      lint.try_lint()
    end, { desc = "Lint buffer" })
  end,
}
