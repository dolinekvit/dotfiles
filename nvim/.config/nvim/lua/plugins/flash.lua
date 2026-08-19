-- flash.nvim — jump anywhere on screen. Press `s` then 2 characters you can
-- see; labels appear on every match, hit the label to teleport there. Also
-- enhances f/t/F/T and `/` search with jump labels.
return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {},
  -- flash jump lives on <leader>s / <leader>S so plain `s`/`S` keep their
  -- built-in meaning (substitute char / line). f/t/F/T and `/` search are still
  -- flash-enhanced automatically — that comes from opts, not these keys.
  keys = {
    { "<leader>s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
    { "<leader>S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter select" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter search" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash in search" },
  },
}
