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
