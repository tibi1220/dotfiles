local map = vim.keymap.set

-- Clipboard
map({ "n", "x" }, "<leader>y", '"+y', { desc = "Copy to clipboard" })
map("n", "<leader>yy", '"+yy', { desc = "Copy line to clipboard" })

map("n", "<leader>p", '"+p', { desc = "Paste from clipboard after cursor" })
map("n", "<leader>P", '"+P', { desc = "Paste from clipboard before cursor" })

map("x", "<leader>p", '"+P', { desc = "Replace selection from clipboard" })
map("x", "<leader>P", '"_dP', { desc = "Replace selection and preserve register" })

-- Cmd+C copies the selection to the clipboard, like "+y. Terminals don't send
-- Cmd+key to programs (and tmux couldn't pass it on), so kitty sends F20
-- instead while Neovim has focus (kitty.conf). Neovim tells kitty it has
-- focus with the user variable in_editor, set on start / focus and cleared
-- on exit / suspend / focus moving to another tmux pane or window. Inside
-- tmux the message is wrapped so tmux passes it on (allow-passthrough on).
-- kitty sends F20's classic code (ESC[34~); Neovim reads that as <F20>, but
-- inside tmux as <F22> (the two number the keys above F12 differently)
map("x", "<F20>", '"+y', { desc = "Copy selection to clipboard (Cmd+C)" })
map("x", "<F22>", '"+y', { desc = "Copy selection to clipboard (Cmd+C, in tmux)" })

local function set_in_editor(on)
  local seq = "\27]1337;SetUserVar=in_editor" .. (on and "=MQ==" or "") .. "\7"
  if vim.env.TMUX then
    seq = "\27Ptmux;" .. seq:gsub("\27", "\27\27") .. "\27\\"
  end
  if vim.api.nvim_ui_send then
    vim.api.nvim_ui_send(seq)
  else
    io.stdout:write(seq)
  end
end

local in_editor = vim.api.nvim_create_augroup("KittyInEditor", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "VimResume", "FocusGained" }, {
  group = in_editor,
  desc = "Tell kitty Neovim has focus (Cmd+C copies the selection)",
  callback = function()
    set_in_editor(true)
  end,
})
vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend", "FocusLost" }, {
  group = in_editor,
  desc = "Tell kitty Neovim lost focus (Cmd+C back to kitty's copy)",
  callback = function()
    set_in_editor(false)
  end,
})

-- Keep selection after indenting
map("v", "<", "<gv", { desc = "Indent left and keep selection" })
map("v", ">", ">gv", { desc = "Indent right and keep selection" })

-- Move selected lines
map("x", "J", ":move '>+1<CR>gv-gv", { desc = "Move selected lines down" })
map("x", "K", ":move '<-2<CR>gv-gv", { desc = "Move selected lines up" })

-- Misc
vim.keymap.set("n", "<leader>cp", function()
  local path = vim.fn.expand "%:p"
  vim.fn.setreg("+", path)
  vim.notify("Copied " .. path)
end, { desc = "Copy absolute file path" })
