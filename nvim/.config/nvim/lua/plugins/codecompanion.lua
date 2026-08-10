-- CodeCompanion — in-editor AI (chat, inline edits, agentic tools).
--
-- Uses Claude Code over ACP (Agent Client Protocol), which runs on your
-- existing Claude subscription — no separate Anthropic API billing. The bridge
-- is the npm package @zed-industries/claude-code-acp (installed globally).
--
-- One-time auth: `claude setup-token` mints a long-lived token; export it as
-- CLAUDE_CODE_OAUTH_TOKEN. (If the Claude Code CLI is already logged in, the
-- adapter can also use that session.)
return {
  "olimorris/codecompanion.nvim",
  version = "^19.0.0", -- pin major; majors ship breaking changes
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd" },
  keys = {
    { "<leader>aa", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "AI: actions" },
    { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "AI: toggle chat" },
    { "<leader>ai", ":CodeCompanion ", mode = { "n", "v" }, desc = "AI: inline prompt" },
    { "<leader>ad", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "AI: add selection to chat" },
  },
  opts = {
    -- Use the Claude Code ACP adapter for everything. It runs the
    -- `claude-agent-acp` bridge and reads CLAUDE_CODE_OAUTH_TOKEN from your
    -- shell environment (set once via `claude setup-token`), so it bills your
    -- subscription rather than the Anthropic API.
    strategies = {
      chat = { adapter = "claude_code" },
      inline = { adapter = "claude_code" },
    },
  },
}
