-- cord.nvim — Discord Rich Presence. Shows what you're editing (file, language,
-- workspace, elapsed time) in your Discord status. Needs the Discord desktop
-- app running; the server binary is auto-downloaded via curl on first use.
return {
  "vyfor/cord.nvim",
  build = ":Cord update",
  event = "VeryLazy",
  opts = {
    editor = {
      tooltip = "大波 · Neovim", -- hover text on the editor icon
    },
    idle = {
      enabled = true,
      timeout = 300000, -- show "idle" after 5 min of inactivity
      tooltip = "AFK",
    },
  },
}
