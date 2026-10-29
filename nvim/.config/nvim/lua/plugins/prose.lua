-- Writing / markdown support.
return {
  -- Live, in-buffer markdown rendering (headings, code blocks, lists, tables)
  -- drawn in the colorscheme's colours.
  {
    "OXY2DEV/markview.nvim",
    lazy = false, -- lazy-loads itself; lazy.nvim lazy-loading only slows previews
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      markdown = {
        -- Quote bars on soft-wrapped lines land mid-sentence (in zen-mode
        -- they're computed for the hidden full-width window), so only mark
        -- the first line.
        block_quotes = { wrap = false },
        -- No icons or gutter signs: colour and the heading bar already
        -- carry the hierarchy.
        headings = {
          heading_1 = { icon = "", sign = false },
          heading_2 = { icon = "", sign = false },
          heading_3 = { icon = "", sign = false },
          heading_4 = { icon = "", sign = false },
          heading_5 = { icon = "", sign = false },
          heading_6 = { icon = "", sign = false },
        },
        code_blocks = { sign = false },
      },
      markdown_inline = {
        -- Colour only the box, not the item text: an open todo in red reads
        -- like an error.
        checkboxes = {
          checked = { scope_hl = false },
          unchecked = { scope_hl = false },
        },
      },
    },
  },
}
