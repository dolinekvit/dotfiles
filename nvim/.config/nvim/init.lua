-- ~/.config/nvim/init.lua
-- 大波 — A Japanese-inspired Neovim config (kanagawa)
--
-- Load order:
--   1. options  — core editor behaviour
--   2. keymaps  — leader key + shortcuts
--   3. lazy     — bootstraps the plugin manager, which loads lua/plugins/*

require("config.options")
require("config.keymaps")
require("config.lazy")
