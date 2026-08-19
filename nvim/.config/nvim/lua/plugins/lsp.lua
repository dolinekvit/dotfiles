-- LSP + autocomplete.
--
-- mason installs language servers; mason-lspconfig (v2.x) auto-enables them via
-- Neovim's built-in vim.lsp.config / vim.lsp.enable. nvim-cmp draws the popup.
--
-- NOTE: mason-lspconfig 2.x removed the old `handlers = {}` pattern. Per-server
-- config now goes through vim.lsp.config("<name>", {...}); vim.lsp.config("*")
-- sets defaults shared by every server (here: the cmp capabilities, which are
-- what make auto-import edits and snippet completions actually apply).
return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "williamboman/mason.nvim", config = true },
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      -- Keymaps + inlay hints, set only where a language server actually attaches.
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local function map(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gr", vim.lsp.buf.references, "References")
          map("K", vim.lsp.buf.hover, "Hover docs")
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>d", vim.diagnostic.open_float, "Line diagnostics")
          map("]d", vim.diagnostic.goto_next, "Next diagnostic")
          map("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
          -- Formatting is handled by conform.nvim (<leader>cf), which falls
          -- back to this LSP's formatter for filetypes Prettier doesn't cover.

          -- Turn on inlay hints (param names, inferred types) where supported.
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
          end
        end,
      })

      -- Capabilities advertised to every server: this is what tells servers we
      -- support snippet + resolve edits, so auto-imports apply on <CR>.
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      vim.lsp.config("*", { capabilities = capabilities })

      -- lua_ls: stop "undefined global vim" warnings in this config.
      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })

      -- vtsls: the TypeScript/React server (wraps VS Code's tsserver). Rich
      -- auto-imports, JSX prop completion, and inlay hints.
      vim.lsp.config("vtsls", {
        settings = {
          complete_function_calls = true,
          vtsls = {
            enableMoveToFileCodeAction = true, -- backs the built-in "move to file" refactor
            experimental = {
              maxInlayHintLength = 30,
              completion = { enableServerSideFuzzyMatch = true },
            },
          },
          typescript = {
            updateImportsOnFileMove = { enabled = "always" },
            suggest = { completeFunctionCalls = true },
            preferences = {
              includeCompletionsForModuleExports = true, -- auto-import useState, etc.
              includeCompletionsForImportStatements = true,
              importModuleSpecifier = "shortest",
              quoteStyle = "single",
            },
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = false }, -- keep JSX lines readable
            },
          },
          javascript = {
            updateImportsOnFileMove = { enabled = "always" },
            suggest = { completeFunctionCalls = true },
            preferences = {
              includeCompletionsForModuleExports = true,
              includeCompletionsForImportStatements = true,
              importModuleSpecifier = "shortest",
            },
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = false },
            },
          },
        },
      })
      -- eslint + emmet_language_server need no override: the "*" capabilities and
      -- their built-in configs (flat-config + JSX filetype detection) are enough.

      require("mason-lspconfig").setup({
        -- Auto-installed and auto-enabled. vtsls = TS/React; eslint = lint;
        -- emmet_language_server = JSX emmet; intelephense = PHP; lua_ls = Lua.
        ensure_installed = {
          "lua_ls", "intelephense", "vtsls", "eslint", "emmet_language_server",
          -- tailwindcss only attaches in projects that have a Tailwind config,
          -- so it's harmless in non-Tailwind projects.
          "tailwindcss",
        },
      })
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      {
        "L3MON4D3/LuaSnip",
        build = "make install_jsregexp",
        dependencies = {
          -- Snippet collections. friendly-snippets covers most languages;
          -- vim-react-snippets adds the ES7 React set (rafce, useState, etc.).
          "rafamadriz/friendly-snippets",
          "mlaursen/vim-react-snippets",
        },
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
          require("vim-react-snippets").setup()
        end,
      },
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          -- <C-Space> is taken by macOS (switch input source), so use <C-l>
          -- to force the completion menu open. It also pops up automatically
          -- as you type, so this is only for triggering it manually.
          ["<C-l>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },
}
