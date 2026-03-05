-- if vim.env.SSH_CONNECTION or vim.env.SSH_TTY then
--   local osc52 = require("vim.ui.clipboard.osc52")
--   vim.g.clipboard = {
--     name = "OSC 52",
--     copy = {
--       ["+"] = osc52.copy("+"),
--       ["*"] = osc52.copy("*"),
--     },
--     paste = {
--       ["+"] = function()
--         return { "" }
--       end,
--       ["*"] = function()
--         return { "" }
--       end,
--     },
--   }
-- end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- vim.opt.clipboard = "unnamedplus"
