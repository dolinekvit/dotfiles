-- Core editor behaviour (no plugins required)

local opt = vim.opt

-- Leader key must be set before plugins load. Space is ergonomic and works
-- the same in every mode.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Line numbers: absolute on the current line, relative elsewhere, for fast
-- motions like 5j / 12k.
opt.number = true
opt.relativenumber = true

-- Indentation: 2 spaces by default; filetype plugins override where needed.
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.breakindent = true -- wrapped lines keep their indent

-- Search: case-insensitive unless the query has a capital; highlight as you go.
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- Persistent undo — survives closing the file.
opt.undofile = true
opt.swapfile = false
opt.backup = false

-- Use the system clipboard for yank/paste.
opt.clipboard = "unnamedplus"

-- UI niceties
opt.termguicolors = true -- 24-bit colour, required by kanagawa
opt.signcolumn = "yes"   -- stable gutter so text doesn't jump
opt.cursorline = true
opt.scrolloff = 8        -- keep context above/below the cursor
opt.sidescrolloff = 8
opt.wrap = false         -- off by default; markdown/text re-enable it
opt.splitright = true
opt.splitbelow = true
opt.mouse = "a"
opt.showmode = false     -- the statusline already shows the mode

-- Faster updates (git signs, diagnostics) and a sane timeout for which-key.
opt.updatetime = 250
opt.timeoutlen = 400

-- Show whitespace meaningfully.
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Prose mode: soft-wrap, spell-check, and visual-line movement for text
-- filetypes (markdown, plain text, git commit messages).
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit" },
  desc = "Prose-friendly settings for text filetypes",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true -- wrap at word boundaries, not mid-word
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us"
    -- Move by visual lines when text is wrapped.
    vim.keymap.set("n", "j", "gj", { buffer = true })
    vim.keymap.set("n", "k", "gk", { buffer = true })
  end,
})

-- Briefly highlight yanked text — a small, satisfying visual confirmation.
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight on yank",
  callback = function()
    vim.highlight.on_yank({ timeout = 150 })
  end,
})
