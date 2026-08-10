-- Treesitter — accurate, fast syntax highlighting and indentation.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master", -- stable/classic API; "main" is an incompatible rewrite
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-treesitter.configs").setup({
      -- A practical starter set; install more later with :TSInstall <lang>.
      ensure_installed = {
        "lua", "vim", "vimdoc", "bash", "json", "yaml", "toml",
        "markdown", "markdown_inline", "python", "javascript",
        "typescript", "tsx", "html", "css", "gitcommit",
      },
      auto_install = true, -- grab missing parsers on the fly
      highlight = { enable = true },
      indent = { enable = true },
    })
  end,
}
