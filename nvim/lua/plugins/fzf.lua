return {
  "ibhagwan/fzf-lua",
  opts = {
    grep = {
      rg_opts = table.concat({
        "--column",
        "--line-number",
        "--no-heading",
        "--color=always",
        "--smart-case",
        "--max-columns=4096",
        "-e",
      }, " "),
    },
  },
}
