-- Define our own mappings instead of the plugin defaults (read when the
-- plugin's plugin/ file runs, after init.lua).
vim.g.tmux_navigator_no_mappings = 1

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
