-- hardtime.nvim — the "training wheels". Nudges you (and after a few repeats,
-- blocks you) when you spam hjkl or the arrow keys, so you reach for a real
-- motion (f/t, w/b, counts, search) instead. Toggle anytime with :Hardtime toggle.
return {
  "m4xshen/hardtime.nvim",
  lazy = false,
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    -- Show a hint about the more efficient motion when you're being inefficient.
    hint = true,
    -- After this many repeated presses of the same key, it gets blocked.
    max_count = 4,
    -- Don't fight you in these buffer/file types.
    disabled_filetypes = {
      "neo-tree", "alpha", "lazy", "mason", "TelescopePrompt",
      "help", "qf", "codecompanion",
    },
  },
}
