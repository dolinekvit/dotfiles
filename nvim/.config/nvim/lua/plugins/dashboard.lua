-- Startup dashboard (alpha-nvim), kept quiet: a small wordmark, one line of
-- shortcuts, and a haiku near the bottom of the screen.
return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    local alpha = require("alpha")

    local shortcuts = {
      { "f", "find", "<cmd>Telescope find_files<CR>" },
      { "r", "recent", "<cmd>Telescope oldfiles<CR>" },
      { "g", "grep", "<cmd>Telescope live_grep<CR>" },
      { "e", "files", "<cmd>Neotree toggle<CR>" },
      { "n", "new", "<cmd>ene <BAR> startinsert<CR>" },
      { "c", "config", "<cmd>edit ~/.config/nvim/init.lua<CR>" },
      { "u", "update", "<cmd>Lazy sync<CR>" },
      { "q", "quit", "<cmd>qa<CR>" },
    }

    -- Build "f find   r recent   …" with the keys bright and the words dim.
    local line, hl = "", {}
    for i, s in ipairs(shortcuts) do
      if i > 1 then line = line .. "   " end
      table.insert(hl, { "Normal", #line, #line + 1 })
      table.insert(hl, { "Comment", #line + 1, #line + 1 + #s[2] + 1 })
      line = line .. s[1] .. " " .. s[2]
    end

    -- A small collection of haiku; one is picked at random each launch.
    local haiku = {
      "古池や 蛙飛び込む 水の音",
      "閑かさや 岩にしみ入る 蝉の声",
      "菜の花や 月は東に 日は西に",
      "雀の子 そこのけそこのけ 御馬が通る",
      "初しぐれ 猿も小蓑を ほしげなり",
    }
    math.randomseed(os.time())

    alpha.setup({
      layout = {
        { type = "padding", val = function() return math.floor(vim.o.lines * 0.38) end },
        { type = "text", val = "n e o v i m", opts = { position = "center", hl = "Normal" } },
        { type = "padding", val = 2 },
        { type = "text", val = line, opts = { position = "center", hl = hl } },
        { type = "padding", val = function() return math.max(2, math.floor(vim.o.lines * 0.38) - 6) end },
        { type = "text", val = haiku[math.random(#haiku)], opts = { position = "center", hl = "Comment" } },
      },
      opts = { margin = 0 },
    })

    -- The shortcuts are plain text, so bind their keys on the dashboard buffer.
    local grp = vim.api.nvim_create_augroup("AlphaStatusline", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = grp,
      pattern = "alpha",
      callback = function(ev)
        for _, s in ipairs(shortcuts) do
          vim.keymap.set("n", s[1], s[3], { buffer = ev.buf, nowait = true, silent = true })
        end
      end,
    })

    -- Hide the statusline/tabline while the dashboard is showing, and
    -- restore them when we leave the alpha buffer.
    vim.api.nvim_create_autocmd("User", {
      group = grp,
      pattern = "AlphaReady",
      callback = function()
        vim.opt.laststatus = 0
        vim.opt.showtabline = 0
      end,
    })
    -- lualine loads later (VeryLazy) and switches its global statusline back on.
    vim.api.nvim_create_autocmd("User", {
      group = grp,
      pattern = "VeryLazy",
      callback = function()
        if vim.bo.filetype == "alpha" then vim.opt.laststatus = 0 end
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
}
