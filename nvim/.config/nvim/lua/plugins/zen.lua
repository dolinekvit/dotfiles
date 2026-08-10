-- Zen mode — distraction-free, centered editing. Twilight dims everything
-- except the paragraph under the cursor for a calm, focused feel.
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
        width = 90,        -- columns of centered text
        options = {
          number = false,
          relativenumber = false,
          signcolumn = "no",
          cursorline = false,
        },
      },
      plugins = {
        twilight = { enabled = true }, -- dim inactive paragraphs
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
