-- lazygit.nvim — open the lazygit TUI in a floating window inside Neovim.
-- Requires the `lazygit` binary (installed via Homebrew).
return {
  "kdheepak/lazygit.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  keys = {
    { "<leader>gl", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    { "<leader>gf", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (current file history)" },
  },
  init = function()
    vim.g.lazygit_use_custom_config_file_path = 1
    vim.g.lazygit_config_file_path =
      vim.fn.expand("~/.config/lazygit/config.yml")
  end,
}
