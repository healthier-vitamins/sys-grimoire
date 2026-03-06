return {
  {
    "Mofiqul/dracula.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("dracula").setup({
        colors = {
          bg = "#0D0D0D",
          black = "#000000",
          menu = "#111111",
          selection = "#5D5F9F",
          visual = "#1A1A2A",
          nontext = "#2A2A3A",
          gutter_fg = "#3D3D3D",
          comment = "#7080A4",
        },
        transparent_bg = false,
        italic_comment = true,
        -- Added overrides to fix blinding Diffview colors while preserving syntax
        overrides = function()
          return {
            DiffAdd = { bg = "#1e3a29", fg = "NONE" },
            DiffDelete = { bg = "#3a1e1e", fg = "NONE" },
            DiffChange = { bg = "#252535", fg = "NONE" },
            DiffText = { bg = "#3a4b5c", fg = "NONE" },
            -- Tone down visual selection and allow syntax to show through
            Visual = { bg = "#2B2D46", fg = "NONE" },
            CursorLine = { bg = "#1A1A2A", fg = "NONE" },
          }
        end,
      })
      vim.cmd("colorscheme dracula")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "dracula",
    },
  },
}
