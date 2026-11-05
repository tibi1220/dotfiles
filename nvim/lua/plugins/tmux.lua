-- Define our own mappings instead of the plugin defaults.
vim.g.tmux_navigator_no_mappings = 1

vim.pack.add { "https://github.com/christoomey/vim-tmux-navigator" }

local map = vim.keymap.set

map("n", "<C-h>", "<Cmd>TmuxNavigateLeft<CR>", {
  silent = true,
  desc = "Navigate left across Neovim and tmux",
})
map("n", "<C-j>", "<Cmd>TmuxNavigateDown<CR>", {
  silent = true,
  desc = "Navigate down across Neovim and tmux",
})
map("n", "<C-k>", "<Cmd>TmuxNavigateUp<CR>", {
  silent = true,
  desc = "Navigate up across Neovim and tmux",
})
map("n", "<C-l>", "<Cmd>TmuxNavigateRight<CR>", {
  silent = true,
  desc = "Navigate right across Neovim and tmux",
})
