return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    -- Keymaps to trigger the AI
    keys = {
      { "<C-a>", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "AI Actions" },
      { "<leader>a", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "AI Chat" },
      { "ga", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "Add Code to Chat" },
    },
    opts = {
      -- 1. Tell the plugin to use Ollama for everything
      strategies = {
        chat = { adapter = "ollama" },
        inline = { adapter = "ollama" },
        agent = { adapter = "ollama" },
      },

      -- 2. Configure the Ollama adapter to use your specific model
      adapters = {
        ollama = function()
          return require("codecompanion.adapters").extend("ollama", {
            schema = {
              model = {
                default = "qwen3:latest",
              },
            },
          })
        end,
      },

      -- 3. Your requested Log Level settings
      -- Note: In lazy.nvim, this 'opts' table is passed to require("codecompanion").setup(opts)
      -- The plugin expects its internal options (like log_level) to be in a nested 'opts' table.
      opts = {
        log_level = "DEBUG",
      },
    },
  },
}
