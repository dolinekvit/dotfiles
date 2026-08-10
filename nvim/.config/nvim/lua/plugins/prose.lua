-- Writing / markdown support.
return {
  -- Live, in-buffer markdown rendering (headings, code blocks, lists, tables)
  -- drawn with kanagawa-friendly colours.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {},
  },
}
