return {
  "esmuellert/codediff.nvim",
  -- Lazy load on these events/commands
  cmd = "CodeDiff",

  -- This ensures setup() is called with default options
  opts = {},

  -- LazyVim will handle the keymap and loading for you
  keys = {
    { "<leader>gc", "<cmd>CodeDiff<cr>", desc = "CodeDiff (VSCode Style)" },
  },
}
