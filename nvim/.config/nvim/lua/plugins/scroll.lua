-- neoscroll — gentle animated scrolling instead of instant jumps.
return {
  "karb94/neoscroll.nvim",
  event = "VeryLazy",
  opts = {
    easing = "sine",        -- soft ease-in/out
    duration_multiplier = 1.0,
    mappings = {            -- animate the usual scroll keys
      "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb",
    },
  },
}
