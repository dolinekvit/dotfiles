-- Zen mode — distraction-free, centered reading and editing. Twilight dims
-- everything except the paragraph under the cursor; it's off by default
-- because that hurts skimming — toggle it with :Twilight when writing.
return {
  {
    "folke/zen-mode.nvim",
    dependencies = { "folke/twilight.nvim" },
    cmd = "ZenMode",
    keys = {
      { "<leader>z", "<cmd>ZenMode<CR>", desc = "Toggle Zen mode" },
    },
    opts = {
      window = {
        width = 80,        -- columns of centered text; ~80 is easiest to read
        options = {
          number = false,
          relativenumber = false,
          signcolumn = "no",
          cursorline = false,
        },
      },
      plugins = {
        twilight = { enabled = false }, -- :Twilight dims inactive paragraphs
        gitsigns = { enabled = false },
        options = { laststatus = 0 },  -- hide the statusline in zen
      },
    },
  },

  {
    "folke/twilight.nvim",
    cmd = { "Twilight", "TwilightEnable" },
    opts = {
      dimming = { alpha = 0.25 }, -- how dark the inactive text gets
      context = 12,              -- lines of context kept bright
    },
  },
}
