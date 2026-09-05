-- Telescope — fuzzy finder for files, text, buffers, help, and more.
--
-- Tracks `master`, not the `0.1.x` tag branch: 0.1.x is frozen at May 2024 and
-- its preview highlighter calls `nvim-treesitter.parsers.ft_to_lang()`, a
-- master-branch nvim-treesitter API that no longer exists. `master` uses
-- Neovim's own `vim.treesitter` API instead. Requires Neovim >= 0.11.7.
return {
  "nvim-telescope/telescope.nvim",
  branch = "master",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- Native fzf sorter — much faster matching. Built with `make`.
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  cmd = "Telescope",
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Grep in project" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Find help" },
    { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
    { "<leader>fw", "<cmd>Telescope grep_string<CR>", desc = "Find word under cursor" },
    { "<leader><leader>", "<cmd>Telescope find_files<CR>", desc = "Find files" },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        prompt_prefix = "  ",
        selection_caret = "  ",
        path_display = { "truncate" },
        sorting_strategy = "ascending",
        layout_config = {
          horizontal = { prompt_position = "top", preview_width = 0.55 },
        },
      },
    })
    pcall(telescope.load_extension, "fzf")
  end,
}
