-- vague.nvim — a calm, low-contrast dark theme: soft greys with a few
-- desaturated accents, so the code is the only thing asking for attention.
return {
  {
    "vague-theme/vague.nvim",
    lazy = false,    -- load on startup
    priority = 1000, -- before any other plugin, so colours are set first
    config = function()
      require("vague").setup({
        on_highlights = function(hl, c)
          -- Popups (which-key, LSP hover, telescope) share the editor
          -- background and are set apart only by a faint frame. vague's own
          -- float shade is blue-tinted and reads like the old kanagawa bg.
          hl.NormalFloat = { fg = c.fg, bg = c.bg }
          hl.FloatBorder = { fg = c.line, bg = c.bg }
          hl.FloatTitle = { fg = c.comment, bg = c.bg }
          hl.TelescopeBorder = { fg = c.line }
          hl.TelescopeTitle = { fg = c.comment }
          -- vague gives every heading level one colour; markview builds its
          -- six palettes (headings, callouts, checkboxes) from these, so
          -- without them everything renders the same muted blue.
          hl["@markup.heading.1.markdown"] = { fg = c.func, bold = true }
          hl["@markup.heading.2.markdown"] = { fg = c.string, bold = true }
          hl["@markup.heading.3.markdown"] = { fg = c.warning, bold = true }
          hl["@markup.heading.4.markdown"] = { fg = c.plus, bold = true }
          hl["@markup.heading.5.markdown"] = { fg = c.hint, bold = true }
          hl["@markup.heading.6.markdown"] = { fg = c.parameter, bold = true }
          -- Quotes and callout bodies default to comment grey (~3:1 contrast),
          -- too dim for whole paragraphs. This muted blue-grey is ~7:1 and
          -- still sets wrapped quote lines apart from body text.
          hl["@markup.quote"] = { fg = c.operator }
          -- Dim spell squiggles: typos stay findable without every tool name
          -- in prose shouting red.
          hl.SpellBad = { sp = c.comment, undercurl = true }
          hl.SpellCap = { sp = c.comment, undercurl = true }
          hl.SpellLocal = { sp = c.comment, undercurl = true }
          hl.SpellRare = { sp = c.comment, undercurl = true }
        end,
      })
      vim.cmd.colorscheme("vague")
    end,
  },

  -- Grey file icons everywhere (neo-tree, telescope, statusline) instead of a
  -- rainbow per filetype.
  { "nvim-tree/nvim-web-devicons", opts = { color_icons = false } },
}
