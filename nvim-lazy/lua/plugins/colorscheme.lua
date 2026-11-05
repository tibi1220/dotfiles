return {
  "EdenEast/nightfox.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd "colorscheme nightfox"
    vim.cmd "hi EndOfBuffer guifg=#738091 guibg=NONE"
  end,
}
