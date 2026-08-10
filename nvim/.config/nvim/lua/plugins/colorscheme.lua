-- kanagawa.nvim — inspired by Katsushika Hokusai's "The Great Wave off
-- Kanagawa". The default "wave" variant is a deep sumi-ink background with
-- muted wave-blue and autumn-leaf accents.
return {
  "rebelot/kanagawa.nvim",
  lazy = false,    -- load on startup
  priority = 1000, -- before any other plugin, so colours are set first
  config = function()
    require("kanagawa").setup({
      compile = true,
      dimInactive = false, -- keep all windows (incl. file explorer) the same bg
      theme = "wave",     -- "wave" (dark blue), "dragon" (darker), "lotus" (light)
      background = {
        dark = "wave",
        light = "lotus",
      },
      overrides = function(colors)
        local theme = colors.theme
        return {
          -- Make floating windows (telescope, which-key) blend with the
          -- background instead of standing out as grey boxes.
          NormalFloat = { bg = "none" },
          FloatBorder = { bg = "none" },
          FloatTitle = { bg = "none" },
          -- A softer, ink-wash look for telescope.
          TelescopeBorder = { fg = theme.ui.bg_dim, bg = theme.ui.bg_dim },
          TelescopeNormal = { bg = theme.ui.bg_dim },
          TelescopePromptNormal = { bg = theme.ui.bg_p1 },
          TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
          TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
          TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
          TelescopePreviewNormal = { bg = theme.ui.bg_dim },
          TelescopePreviewBorder = { fg = theme.ui.bg_dim, bg = theme.ui.bg_dim },
        }
      end,
    })
    vim.cmd.colorscheme("kanagawa")
  end,
}
