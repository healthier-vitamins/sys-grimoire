-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
vim.keymap.set("n", "<leader>gd", function()
  -- Check if Diffview is currently open
  local lib = require("diffview.lib")
  local view = lib.get_current_view()

  if view then
    vim.cmd("DiffviewClose")
  else
    vim.cmd("DiffviewOpen")
  end
end, { desc = "Toggle Git Diffview" })

local map = vim.keymap.set

-- Selection using Shift + Arrow keys
map("n", "<S-Up>", "v<Up>", { desc = "Select Up" })
map("n", "<S-Down>", "v<Down>", { desc = "Select Down" })
map("n", "<S-Left>", "v<Left>", { desc = "Select Left" })
map("n", "<S-Right>", "v<Right>", { desc = "Select Right" })

-- Continue selection in Visual Mode
map("v", "<S-Up>", "<Up>", { desc = "Extend Selection Up" })
map("v", "<S-Down>", "<Down>", { desc = "Extend Selection Down" })
map("v", "<S-Left>", "<Left>", { desc = "Extend Selection Left" })
map("v", "<S-Right>", "<Right>", { desc = "Extend Selection Right" })

-- Support for Insert Mode (optional)
map("i", "<S-Up>", "<Esc>v<Up>", { desc = "Select Up from Insert" })
map("i", "<S-Down>", "<Esc>v<Down>", { desc = "Select Down from Insert" })
map("i", "<S-Left>", "<Esc>v<Left>", { desc = "Select Left from Insert" })
map("i", "<S-Right>", "<Esc>v<Right>", { desc = "Select Right from Insert" })
