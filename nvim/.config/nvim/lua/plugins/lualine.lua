-- Lualine — a plain-text statusline: no coloured blocks or arrows, just a
-- tinted mode dot and dim grey info on the editor background (vague colours).
local bg, fg, dim = "#141415", "#cdcdcd", "#606079"
local function mode(color)
  return {
    a = { fg = color, bg = bg },
    b = { fg = dim, bg = bg },
    c = { fg = fg, bg = bg },
  }
end

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = {
    options = {
      theme = {
        normal = mode("#6e94b2"),
        insert = mode("#7fa563"),
        visual = mode("#f3be7c"),
        replace = mode("#d8647e"),
        command = mode("#bb9dbd"),
        inactive = mode(dim),
      },
      globalstatus = true, -- one statusline for all windows
      section_separators = "",
      component_separators = "",
    },
    sections = {
      lualine_a = { { "mode", fmt = function(m) return "● " .. m:lower() end } },
      lualine_b = {},
      lualine_c = { { "filename", path = 1 }, { "diff", colored = false, color = { fg = dim } } },
      lualine_x = { "diagnostics", { "branch", color = { fg = dim } } },
      lualine_y = {},
      lualine_z = { { "location", color = { fg = dim, bg = bg } } },
    },
  },
}
