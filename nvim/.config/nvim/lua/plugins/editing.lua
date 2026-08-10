-- Small quality-of-life editing plugins, grouped together.
return {
  -- which-key — popup that shows the keybindings available after a prefix.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>h", group = "git hunk" },
        { "<leader>g", group = "git" },
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>a", group = "ai" },
        { "<leader>n", group = "package" },
        { "<leader>u", group = "ui/toggle" },
      },
    },
  },

  -- Auto-close brackets, quotes, etc.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  -- gcc to comment a line, gc in visual mode for a selection.
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = true,
  },

  -- Indentation guides.
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    main = "ibl",
    opts = { scope = { enabled = true } },
  },
}
