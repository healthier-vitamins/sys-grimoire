-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

if vim.env.SSH_CONNECTION or vim.env.SSH_TTY then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = function()
        return { "" }
      end,
      ["*"] = function()
        return { "" }
      end,
    },
  }
  vim.opt.clipboard = "unnamedplus"
else
  -- Local Windows/WSL desktop: keep win32yank
  vim.g.clipboard = {
    name = "win32yank-wsl",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
  }
  vim.opt.clipboard = "unnamedplus"
end

vim.g.python3_host_prog = vim.fn.expand("~/.virtualenvs/neovim/bin/python")

local opt = vim.opt
opt.shiftwidth = 4 -- Size of an indent
opt.tabstop = 4 -- Number of spaces tabs count for
opt.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
opt.expandtab = true -- Use spaces instead of tabs
