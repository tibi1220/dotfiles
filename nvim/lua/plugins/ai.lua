vim.pack.add { "https://github.com/coder/claudecode.nvim" }

-- Claude Code inside Neovim, connected the way the official VS Code and
-- JetBrains extensions are: Claude sees the current file and selection,
-- can read LSP diagnostics, and proposes edits as diffs here (accept with
-- :w or <leader>aa, reject with :q or <leader>ad).
--
-- Claude runs in a snacks.nvim terminal along the right side (<leader>ac) or
-- in a floating window (<leader>aF): the same conversation either way. A
-- Claude Code started elsewhere (e.g. in a tmux pane) can connect with /ide.
require("claudecode").setup {
  terminal = {
    provider = "snacks",
    split_side = "right",
    split_width_percentage = 0.35, -- PANEL_WIDTH below
  },
}

local map = vim.keymap.set

-- Size of the floating window, and of the side panel (as in setup above)
local FLOAT_SIZE = 0.85
local PANEL_WIDTH = 0.35

-- Settings for a floating window, centered, FLOAT_SIZE of the screen
local function float_config()
  local width = math.floor(vim.o.columns * FLOAT_SIZE)
  local height = math.floor((vim.o.lines - vim.o.cmdheight) * FLOAT_SIZE)
  return {
    relative = "editor",
    row = math.floor((vim.o.lines - vim.o.cmdheight - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = "rounded",
    title = " Claude Code ",
    title_pos = "center",
    zindex = 50,
  }
end

-- Claude's window, if it's shown (a hidden float stays around with `hide`)
local function claude_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "claudecode" and not vim.api.nvim_win_get_config(win).hide then
      return win
    end
  end
end

local function is_float(win)
  return vim.api.nvim_win_get_config(win).relative ~= ""
end

-- Turn Claude's window into a float or into the side panel, in place. The
-- terminal (and the conversation) stays; claudecode's own hide and show
-- follow whatever the window is now.
local function convert(win, float)
  if float then
    vim.api.nvim_win_set_config(win, float_config())
  else
    vim.api.nvim_win_set_config(win, { split = "right", win = -1 })
    vim.api.nvim_win_set_width(win, math.floor(vim.o.columns * PANEL_WIDTH))
    -- The dimmed backdrop snacks puts behind a float
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "snacks_win_backdrop" then
        pcall(vim.api.nvim_win_close, w, true)
      end
    end
  end
  vim.api.nvim_set_current_win(win)
  vim.cmd.startinsert()
end

-- Show or hide Claude as the side panel (float = false) or a floating
-- window (float = true). Shown the other way, it moves over.
--
-- args (e.g. "--resume") are passed to `claude` when it starts. With args,
-- Claude is only shown, never hidden. Like :ClaudeCode --resume, they do
-- nothing when Claude is already running (shown or hidden): there is only
-- one Claude terminal, so quit that one first (/exit) to resume another
-- conversation.
local function toggle_claude(float, args)
  local terminal = require "claudecode.terminal"
  local win = claude_window()
  if win and is_float(win) == float then
    if args then
      vim.api.nvim_set_current_win(win)
      vim.cmd.startinsert()
    else
      terminal.simple_toggle() -- hide it
    end
    return
  end
  if not win then
    -- Start it, or show it again as it was
    local opts = float and { snacks_win_opts = vim.tbl_extend("force", float_config(), { position = "float" }) } or nil
    terminal.simple_toggle(opts, args)
    win = claude_window()
  end
  if win and is_float(win) ~= float then
    convert(win, float)
  end
end

-- stylua: ignore start
map("n", "<leader>ac", function() toggle_claude(false) end, { desc = "Toggle Claude (side panel)" })
map("n", "<leader>aF", function() toggle_claude(true) end, { desc = "Toggle Claude (floating window)" })
map("n", "<leader>af", "<Cmd>ClaudeCodeFocus<CR>", { desc = "Focus Claude" })
map("n", "<leader>ar", "<Cmd>ClaudeCode --resume<CR>", { desc = "Resume a Claude conversation" })
map("n", "<leader>h", function() toggle_claude(true, "--resume") end, { desc = "Resume a Claude conversation (floating window)" })
map("n", "<leader>aC", "<Cmd>ClaudeCode --continue<CR>", { desc = "Continue the last Claude conversation" })
map("n", "<leader>am", "<Cmd>ClaudeCodeSelectModel<CR>", { desc = "Select Claude model" })
map("n", "<leader>ab", "<Cmd>ClaudeCodeAdd %<CR>", { desc = "Add current file to Claude" })
map("x", "<leader>as", "<Cmd>ClaudeCodeSend<CR>", { desc = "Send selection to Claude" })
map("n", "<leader>aa", "<Cmd>ClaudeCodeDiffAccept<CR>", { desc = "Accept Claude's diff" })
map("n", "<leader>ad", "<Cmd>ClaudeCodeDiffDeny<CR>", { desc = "Reject Claude's diff" })
-- stylua: ignore end

-- In the file explorers: add the file under the cursor
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ClaudeCodeTreeAdd", { clear = true }),
  pattern = { "neo-tree", "snacks_picker_list" },
  desc = "Add the file under the cursor to Claude",
  callback = function(args)
    map("n", "<leader>as", "<Cmd>ClaudeCodeTreeAdd<CR>", { buffer = args.buf, desc = "Add file to Claude" })
  end,
})

-- Ctrl-H / Ctrl-L out of Claude, even while typing (terminal mode):
--   side panel: to the window on the left / right (another split, or the
--               next tmux pane)
--   floating window: hides it, back to the file underneath (<leader>aF
--               brings it back)
-- Not J/K: Claude Code uses Ctrl-J for a new line. Ctrl-L replaces Claude
-- Code's "redraw the screen".
local function leave_claude(direction)
  return function()
    if is_float(vim.api.nvim_get_current_win()) then
      require("claudecode.terminal").simple_toggle() -- hide it
    else
      vim.cmd("TmuxNavigate" .. direction)
    end
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ClaudeCodePanelKeys", { clear = true }),
  pattern = "claudecode",
  desc = "Ctrl-H / Ctrl-L out of Claude",
  callback = function(args)
    map("t", "<C-h>", leave_claude "Left", { buffer = args.buf, desc = "Leave Claude (left)" })
    map("t", "<C-l>", leave_claude "Right", { buffer = args.buf, desc = "Leave Claude (right)" })
  end,
})
