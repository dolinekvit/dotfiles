-- Neo-tree — file explorer sidebar. Toggle with <leader>e.
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  cmd = "Neotree",
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle file explorer" },
  },
  -- `nvim <dir>` would show netrw because neo-tree isn't loaded yet; load it
  -- early in that case so it takes over the directory instead.
  init = function()
    vim.api.nvim_create_autocmd("BufEnter", {
      group = vim.api.nvim_create_augroup("NeotreeStartDirectory", { clear = true }),
      once = true,
      callback = function()
        local stats = vim.uv.fs_stat(vim.fn.argv(0))
        if stats and stats.type == "directory" then require("neo-tree") end
      end,
    })
  end,
  opts = {
    close_if_last_window = true,
    filesystem = {
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = {
        hide_dotfiles = false, -- show dotfiles (you edit configs)
        hide_gitignored = true,
        always_show_by_pattern = { ".env*" },
      },
    },
    window = {
      width = 32,
      mappings = {
        ["<space>"] = "none", -- free up space; it's our leader
      },
    },
  },
}
