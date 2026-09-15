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

-- Docker Compose files are plain `yaml` to Neovim's built-in detection, but
-- every compose language server keys off the `yaml.docker-compose` filetype.
-- Mapping it here (rather than in the LSP plugin spec) guarantees it is
-- registered before the first buffer is read. See lua/plugins/lsp.lua for the
-- yamlls config that consumes it.
vim.filetype.add({
  filename = {
    ["compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["docker-compose.yml"] = "yaml.docker-compose",
  },
  -- Patterns are matched against the full path and are implicitly anchored,
  -- hence the leading `.*/`. These cover variants: compose.override.yaml,
  -- docker-compose.prod.yml, and so on.
  pattern = {
    [".*/compose%.[%w_.-]+%.ya?ml"] = "yaml.docker-compose",
    [".*/docker%-compose%.[%w_.-]+%.ya?ml"] = "yaml.docker-compose",
  },
})

-- Neovim detects the exact filename `Jenkinsfile` as groovy, but not the
-- variants real repos use. Patterns are matched against the full path and are
-- implicitly anchored, hence the leading `.*/`.
vim.filetype.add({
  pattern = {
    [".*/Jenkinsfile%.[%w_.-]+"] = "groovy", -- Jenkinsfile.release, Jenkinsfile.dev
    [".*%.Jenkinsfile"] = "groovy",          -- build.Jenkinsfile, deploy.Jenkinsfile
  },
})

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
