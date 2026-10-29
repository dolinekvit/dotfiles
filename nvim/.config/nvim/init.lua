-- ~/.config/nvim/init.lua
-- 静 — A quiet, Japanese-inspired Neovim config (vague)
--
-- Load order:
--   1. options  — core editor behaviour
--   2. keymaps  — leader key + shortcuts
--   3. lazy     — bootstraps the plugin manager, which loads lua/plugins/*

require("config.options")
require("config.keymaps")
require("config.lazy")
