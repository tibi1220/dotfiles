local map = vim.keymap.set

-- Clipboard
map({ "n", "x" }, "<leader>y", '"+y', { desc = "Copy to clipboard" })
map("n", "<leader>yy", '"+yy', { desc = "Copy line to clipboard" })

map("n", "<leader>p", '"+p', { desc = "Paste from clipboard after cursor" })
map("n", "<leader>P", '"+P', { desc = "Paste from clipboard before cursor" })

map("x", "<leader>p", '"+P', { desc = "Replace selection from clipboard" })
map("x", "<leader>P", '"_dP', { desc = "Replace selection and preserve register" })

-- Keep selection after indenting
map("v", "<", "<gv", { desc = "Indent left and keep selection" })
map("v", ">", ">gv", { desc = "Indent right and keep selection" })

-- Move selected lines
map("x", "J", ":move '>+1<CR>gv-gv", { desc = "Move selected lines down" })
map("x", "K", ":move '<-2<CR>gv-gv", { desc = "Move selected lines up" })
