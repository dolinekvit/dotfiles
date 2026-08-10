-- React/JSX editing niceties.
return {
  -- Auto-close and auto-rename JSX/HTML tags: type <div> and </div> appears;
  -- edit one tag and its pair updates. Hooks into the existing treesitter
  -- parsers at runtime (do NOT enable via the deprecated treesitter.configs way).
  {
    "windwp/nvim-ts-autotag",
    ft = {
      "html", "xml", "markdown",
      "javascript", "javascriptreact",
      "typescript", "typescriptreact",
    },
    opts = {},
  },
}
