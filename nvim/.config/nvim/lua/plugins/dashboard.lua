-- Startup dashboard (alpha-nvim) with a Japanese aesthetic, plus drop.nvim
-- for seasonal falling particles (sakura petals / autumn leaves / snow).
return {
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      -- 富士山 — Mt. Fuji rising over the great wave. Pure ASCII, every line
      -- padded to the same width so alpha's centering keeps it aligned.
      dashboard.section.header.val = {
        [[                                                  ]],
        [[                       /\                         ]],
        [[                      /  \                        ]],
        [[                     / /\ \                       ]],
        [[                    / /  \ \                      ]],
        [[                   / /____\ \                     ]],
        [[                  /__/    \__\                    ]],
        [[                 /            \                   ]],
        [[               _/   /\    /\   \_                 ]],
        [[             _/    /  \  /  \    \_               ]],
        [[       __   /     /    \/    \     \   __         ]],
        [[   \  /  \ /_____/              \_____\ /  \  /    ]],
        [[    \/    V                            V    \/     ]],
        [[  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  ]],
        [[                                                  ]],
        [[          神 奈 川   ·   K A N A G A W A          ]],
        [[                                                  ]],
      }

      dashboard.section.buttons.val = {
        dashboard.button("f", "  Find file", "<cmd>Telescope find_files<CR>"),
        dashboard.button("r", "  Recent files", "<cmd>Telescope oldfiles<CR>"),
        dashboard.button("g", "  Grep text", "<cmd>Telescope live_grep<CR>"),
        dashboard.button("n", "  New file", "<cmd>ene <BAR> startinsert<CR>"),
        dashboard.button("e", "  File explorer", "<cmd>Neotree toggle<CR>"),
        dashboard.button("c", "  Config", "<cmd>edit ~/.config/nvim/init.lua<CR>"),
        dashboard.button("u", "  Update plugins", "<cmd>Lazy sync<CR>"),
        dashboard.button("q", "  Quit", "<cmd>qa<CR>"),
      }

      -- A small collection of haiku; one is picked at random each launch.
      local haiku = {
        { "古池や 蛙飛び込む 水の音", "— Bashō: an old pond, a frog leaps in, the sound of water" },
        { "閑かさや 岩にしみ入る 蝉の声", "— Bashō: such stillness — the cicada's cry sinks into the rocks" },
        { "菜の花や 月は東に 日は西に", "— Buson: rapeseed blossoms — the moon in the east, the sun in the west" },
        { "雀の子 そこのけそこのけ 御馬が通る", "— Issa: little sparrow, move aside — a horse is passing through" },
        { "初しぐれ 猿も小蓑を ほしげなり", "— Bashō: first cold rain — even the monkey seems to want a small straw coat" },
      }
      math.randomseed(os.time())
      local pick = haiku[math.random(#haiku)]
      dashboard.section.footer.val = { pick[1], "", pick[2] }

      -- kanagawa-friendly colours for the sections.
      dashboard.section.header.opts.hl = "Function"   -- wave-blue
      dashboard.section.buttons.opts.hl = "Keyword"
      dashboard.section.footer.opts.hl = "Comment"

      dashboard.opts.layout[1].val = 2 -- top padding
      alpha.setup(dashboard.opts)

      -- Hide the statusline/tabline while the dashboard is showing, and
      -- restore them when we leave the alpha buffer.
      local grp = vim.api.nvim_create_augroup("AlphaStatusline", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = grp,
        pattern = "AlphaReady",
        callback = function()
          vim.opt.laststatus = 0
          vim.opt.showtabline = 0
        end,
      })
      vim.api.nvim_create_autocmd("BufUnload", {
        group = grp,
        pattern = "*",
        callback = function(ev)
          if vim.bo[ev.buf].filetype == "alpha" then
            vim.opt.laststatus = 3
            vim.opt.showtabline = 1
          end
        end,
      })
    end,
  },

  -- drop.nvim — falling sakura petals over the dashboard.
  -- The built-in themes use colour emoji (and "auto" picks tropical beach
  -- emoji in summer), so we define a custom theme of monochrome flower
  -- glyphs tinted with kanagawa's own pink/rose palette instead.
  {
    "folke/drop.nvim",
    event = "VimEnter",
    opts = {
      theme = {
        -- Dingbat florettes — text glyphs, not emoji, so they render as
        -- single-width petals in the colours below.
        symbols = { "❀", "❁", "✿", "✾", "❋", "✽", "*" },
        colors = {
          "#D27E99", -- sakuraPink
          "#E46876", -- waveRed
          "#C4746E", -- autumn red
          "#b8627d", -- deep rose
          "#938AA9", -- springViolet
        },
      },
      max = 40,        -- petals on screen at once
      interval = 150,  -- ms between drops (higher = gentler)
      screensaver = 1000 * 60 * 5, -- drift in after 5 min idle, too
      filetypes = { "alpha", "dashboard" }, -- only animate the start screen
    },
  },
}
