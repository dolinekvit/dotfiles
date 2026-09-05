-- Treesitter — accurate, fast syntax highlighting and indentation.
--
-- Tracks the `main` branch. The old `master` branch was archived upstream and
-- does not support Neovim 0.12: its query directives still assume the
-- pre-0.12 API where a match mapped a capture to a single node rather than a
-- list of nodes, so every markdown fenced code block raised
-- "attempt to call method 'range' (a nil value)" from the highlighter.
--
-- `main` is parsers-and-queries only — there are no modules to configure.
-- Highlighting and indentation come from Neovim's own treesitter API and are
-- switched on per filetype below.
--
-- Requires the tree-sitter CLI on $PATH: `brew install tree-sitter-cli`.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- `main` does not support lazy-loading
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")

    ts.setup({
      -- Prepended to runtimepath, so these parsers and queries take priority.
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    -- A practical starter set; install more later with :TSInstall <lang>.
    -- Neovim already bundles c, lua, markdown, markdown_inline, query, vim and
    -- vimdoc, but installing them keeps parser and queries versioned together.
    ts.install({
      "lua", "vim", "vimdoc", "bash", "json", "yaml", "toml",
      "markdown", "markdown_inline", "python", "javascript",
      "typescript", "tsx", "html", "css", "gitcommit",
    })

    -- Replaces master's `highlight`, `indent` and `auto_install` options.
    local function enable(buf, lang)
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      -- A parser on its own is not enough. Starting treesitter for a language
      -- that has no highlights query paints nothing *and* suppresses Neovim's
      -- built-in syntax fallback, leaving the buffer completely uncoloured.
      if not vim.treesitter.query.get(lang, "highlights") then
        return
      end
      vim.treesitter.start(buf, lang)
      -- Only where the language actually ships indent queries: without them
      -- nvim-treesitter's indentexpr returns 0 for every line, which is worse
      -- than the built-in ftplugin indent it would be replacing.
      if vim.treesitter.query.get(lang, "indents") then
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
      desc = "Start treesitter, installing the parser on the fly if needed",
      callback = function(args)
        local buf = args.buf
        local lang = vim.treesitter.language.get_lang(args.match) or args.match

        if vim.treesitter.language.add(lang) then
          enable(buf, lang)
        elseif vim.tbl_contains(ts.get_available(), lang) then
          ts.install(lang):await(function(err)
            if not err then
              vim.schedule(function()
                enable(buf, lang)
              end)
            end
          end)
        end
      end,
    })
  end,
}
