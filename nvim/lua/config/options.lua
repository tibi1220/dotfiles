vim.g.mapleader = " "
vim.g.maplocalleader = " "

local o = vim.opt

o.backup = false -- Creates backup file
o.clipboard = "unnamedplus" -- Access system clipboard
o.cmdheight = 1 -- Bottom bar height
o.completeopt = { "menuone", "noselect" }
o.conceallevel = 0
o.fileencoding = "utf-8"
o.guifont = "monospace:h17"
o.hlsearch = true -- Highlight all matches on previous search pattern
o.ignorecase = true -- Ignore case in search patterns
o.mouse = "a" -- Allow the mouse to be used in neovim
o.pumheight = 10 -- Pop up menu height
o.showmode = true
o.showtabline = 2
o.smartcase = true
o.smartindent = true
o.splitbelow = true -- Force all horizontal splits to go below current window
o.splitright = true -- Force all vertical splits to go to the right of current window
o.swapfile = false
o.termguicolors = true
o.timeoutlen = 200
o.title = true
o.undofile = true -- Enable persistent undo
o.exrc = true -- Load trusted project-local .nvim.lua files.
o.updatetime = 300 -- Faster completion
o.writebackup = false
o.expandtab = true -- Convert tabs to spaces
o.shiftwidth = 2 -- The number of spaces inserted for each indentation
o.tabstop = 2 -- Insert 2 spaces for a tab
o.cursorline = true -- Highlight the current line
o.number = true -- Set numbered lines
o.relativenumber = false -- No relative numbered lines
o.numberwidth = 4
o.signcolumn = "yes" -- Always show the sign column, otherwise it would shift the text each time
o.wrap = false
o.scrolloff = 4 -- Number of lines above/below cursor
o.sidescrolloff = 4 -- Number of cols next to cursor
o.cc = "80,100,120"

vim.filetype.add {
  extension = {
    mdx = "markdown",
  },
}

-- Persistence uses the native session options.
o.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals" }
