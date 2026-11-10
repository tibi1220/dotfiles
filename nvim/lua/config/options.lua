vim.g.mapleader = " "
vim.g.maplocalleader = " "

local options = {
  completeopt = { "menu", "menuone", "noselect", "popup" },
  ignorecase = true,
  smartcase = true,
  splitbelow = true,
  splitright = true,
  undofile = true,
  exrc = true,

  expandtab = true,
  shiftwidth = 2,
  tabstop = 2,

  cursorline = true,
  number = true,
  signcolumn = "yes",
  wrap = false,
  scrolloff = 4,
  sidescrolloff = 4,
  colorcolumn = "80,100,120",
  winborder = "rounded",

  pumheight = 10,
  timeoutlen = 200,
  title = true,

  sessionoptions = {
    "buffers",
    "curdir",
    "tabpages",
    "winsize",
    "help",
    "globals",
  },
}

for name, value in pairs(options) do
  vim.opt[name] = value
end

vim.filetype.add {
  extension = {
    mdx = "markdown",
    -- Theos Logos sources
    x = "objc",
    xi = "objc",
    xm = "objcpp",
    xmi = "objcpp",
  },
}
