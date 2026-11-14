vim.pack.add {
  { src = "https://github.com/folke/snacks.nvim", version = vim.version.range "2" },
}

-- snacks.nvim is a collection of small modules; every module's settings go in
-- this one setup call. Used here for:
--   picker     fuzzy finding (files, text, buffers, LSP results, ...)
--   terminal   the F12 terminal
--   lazygit    lazygit in a float, editing files in this Neovim
--   bufdelete  closing buffers without closing their windows
--   dashboard  the welcome screen
--   image      images and LaTeX math in Neovim (full profile only)
--
-- Loaded in both profiles (see init.lua), since the picker, terminal and
-- dashboard are needed on the Raspberry Pi too.

local essential = vim.env.NVIM_PROFILE == "essential"

--------------------------------------------------------------------------------
------------------------------ Welcome screen ----------------------------------
--------------------------------------------------------------------------------
local logo = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]]

-- Measured once the UI is ready, i.e. after all config and plugins have loaded
local startup_ms

-- "⚡ Neovim · 25 plugins in 63.2 ms"
local function footer()
  local count = 0
  -- info = false skips running git for every plugin (~60 ms)
  for _, plugin in ipairs(vim.pack.get(nil, { info = false })) do
    if plugin.active then
      count = count + 1
    end
  end
  local time = startup_ms and string.format(" in %.1f ms", startup_ms) or ""
  return { footer = string.format("⚡ Neovim · %d plugins%s", count, time), padding = 1 }
end

-- Trains: a night scene with trams, animated under the welcome screen's
-- text (lua/locktrains). Off at startup; the menu's "Trains" entry (t)
-- shows or hides them.
local trains = false

-- Where the menu goes, worked out each time the welcome screen is drawn:
-- without the trains, snacks' own (centered); with them as images (kitty),
-- centered between the top of the screen and the top of the overhead wires;
-- otherwise near the top, leaving room for the text version below.
--
-- snacks reads `opts.row` right after building the menu's lines, so this
-- (an empty section, run while those are built) makes `row` computed when
-- read, from the menu's height (#dashboard.lines) at that moment.
local function position(dashboard)
  dashboard.opts.row = nil
  setmetatable(dashboard.opts, {
    __index = function(_, key)
      if key ~= "row" or not trains then
        return nil
      end
      local wires = require("locktrains.kitty").wires_row(dashboard.win)
      if not wires then
        return 2
      end
      -- The menu from its first to its last line with text (the lines can
      -- end in blank padding, which shouldn't count)
      local first, last
      for i, line in ipairs(dashboard.lines) do
        if line:find "%S" then
          first, last = first or i, i
        end
      end
      if not first then
        return nil
      end
      return math.max(0, math.floor((wires - (last - first + 1)) / 2) - (first - 1))
    end,
  })
  return {}
end

-- Colors, as on the previous (alpha) welcome screen, with the logo in
-- Nightfox blue. default = true lets a colorscheme that styles the dashboard
-- itself win, except for the logo.
local function dashboard_highlights()
  vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#719cd6" })
  for name, target in pairs {
    SnacksDashboardDesc = "Normal",
    SnacksDashboardIcon = "Normal",
    SnacksDashboardKey = "Keyword",
    SnacksDashboardFooter = "Comment",
  } do
    vim.api.nvim_set_hl(0, name, { link = target, default = true })
  end
end
dashboard_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("DashboardHighlights", { clear = true }),
  callback = dashboard_highlights,
})

-- At startup snacks hides the statusline while the welcome screen is shown
-- (laststatus = 0 until it's left): show lualine's bar there anyway. Not in
-- tmux, where the bar is in tmux's status line instead (see editor.lua).
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("DashboardStatusline", { clear = true }),
  pattern = "SnacksDashboardOpened",
  desc = "Show the statusline on the welcome screen",
  callback = function()
    if vim.o.laststatus == 0 and not vim.env.TMUX then
      vim.o.laststatus = 3
    end
  end,
})

vim.api.nvim_create_autocmd("UIEnter", {
  group = vim.api.nvim_create_augroup("DashboardStartupTime", { clear = true }),
  once = true,
  desc = "Show the startup time on the welcome screen",
  callback = function()
    startup_ms = (vim.uv.hrtime() - vim.g.start_time) / 1e6
    if vim.bo.filetype == "snacks_dashboard" then
      Snacks.dashboard.update()
    end
  end,
})

-- The trains, while switched on, are started whenever the welcome screen is
-- drawn (again, e.g. after a resize) and stopped when it closes.
-- At startup the welcome screen fills the first window; opened later
-- (:lua Snacks.dashboard()) it is a floating window
local function dashboard_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "snacks_dashboard" then
      return win, buf
    end
  end
end

-- Stop them, if they were ever started (otherwise nothing of them is loaded)
local function stop_trains()
  if package.loaded["locktrains"] then
    require("locktrains").stop()
  end
end

local trains_group = vim.api.nvim_create_augroup("DashboardTrains", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = trains_group,
  pattern = "SnacksDashboardUpdatePost",
  desc = "Start or stop the trains under the welcome screen",
  callback = function()
    vim.schedule(function()
      local win, buf = dashboard_window()
      -- No "~" on the welcome screen's empty lines (local to its buffer in
      -- that window, so a file opened there later gets the normal value)
      if win then
        vim.api.nvim_set_option_value("fillchars", "eob: ", { scope = "local", win = win })
      end
      if not trains then
        stop_trains()
      elseif win then
        require("locktrains").start(win, buf)
      end
    end)
  end,
})
vim.api.nvim_create_autocmd("User", {
  group = trains_group,
  pattern = "SnacksDashboardClosed",
  desc = "Stop the trains",
  callback = function()
    stop_trains()
  end,
})

-- The menu's "Trains": show or hide them (the menu moves to make room, or
-- back to the middle)
local function toggle_trains()
  trains = not trains
  if not trains then
    stop_trains()
  end
  Snacks.dashboard.update()
end

--------------------------------------------------------------------------------
------------------------------ lazygit -----------------------------------------
--------------------------------------------------------------------------------
-- snacks writes its own lazygit theme from Neovim's highlight groups, which
-- would override the Nightfox theme in lazygit/config.yml. Pass the same
-- colors instead, so lazygit looks the same here and in the tmux popup.
-- Keep in sync with gui.theme in lazygit/config.yml.
local lazygit_theme = {
  activeBorderColor = { "#719cd6", "bold" },
  inactiveBorderColor = { "#39506d" },
  searchingActiveBorderColor = { "#dbc074", "bold" },
  optionsTextColor = { "#719cd6" },
  selectedLineBgColor = { "#2b3b51" },
  inactiveViewSelectedLineBgColor = { "#212e3f" },
  cherryPickedCommitFgColor = { "#131a24" },
  cherryPickedCommitBgColor = { "#63cdcf" },
  markedBaseCommitFgColor = { "#131a24" },
  markedBaseCommitBgColor = { "#dbc074" },
  unstagedChangesColor = { "#c94f6d" },
  defaultFgColor = { "#cdcecf" },
}

--------------------------------------------------------------------------------
------------------------------ Setup -------------------------------------------
--------------------------------------------------------------------------------
require("snacks").setup {
  picker = {
    sources = {
      -- Include dotfiles; .git, and anything in .gitignore, stay hidden
      files = { hidden = true, exclude = { ".DS_Store" } },
      grep = { hidden = true, exclude = { ".DS_Store" } },
    },
  },

  lazygit = {
    -- Edit files in this Neovim (lazygit's `e` closes the float and opens
    -- the file here) and use the theme above
    configure = true,
    config = { gui = { theme = lazygit_theme } },
  },

  bufdelete = { enabled = true },

  dashboard = {
    -- The menu's row is set by `position` (see above)
    preset = {
      header = logo,
      -- stylua: ignore
      keys = {
        { icon = " ", key = "f", desc = "Find file", action = function() Snacks.picker.files() end },
        { icon = " ", key = "e", desc = "New file", action = ":enew | startinsert" },
        { icon = " ", key = "r", desc = "Recent files", action = function() Snacks.picker.recent() end },
        { icon = " ", key = "w", desc = "Find text", action = function() Snacks.picker.grep() end },
        { icon = " ", key = "c", desc = "Config", action = ":edit " .. vim.fn.fnameescape(vim.fn.stdpath "config" .. "/init.lua") },
        { icon = " ", key = "s", desc = "Restore session", action = function() require("persistence").load() end },
        { icon = "󰔬 ", key = "t", desc = "Trains", action = toggle_trains },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = {
      { section = "header", padding = 2 },
      { section = "keys", gap = 1, padding = 1 },
      footer,
      position,
    },
  },

  -- Image viewer: opening an image (png, jpg, gif, webp, pdf, ...) shows it
  -- in the buffer, and images in Markdown are rendered inline. Needs a
  -- terminal with the kitty graphics protocol (kitty, Ghostty, WezTerm;
  -- through tmux with `allow-passthrough on`) and ImageMagick; Ghostscript
  -- for PDFs. Check with :checkhealth snacks.
  -- LaTeX formulas ($...$ in Markdown, math in .tex files) are left as text.
  image = { enabled = not essential, math = { enabled = false } },
}

--------------------------------------------------------------------------------
------------------------------ Keymaps -----------------------------------------
--------------------------------------------------------------------------------
local map = vim.keymap.set

-- stylua: ignore start

-- Picker (the same keys as with Telescope before)
map("n", "<C-p>", function() Snacks.picker.files() end, { desc = "Find files" })
map("n", "<leader>ff", function() Snacks.picker.files() end, { desc = "Find files" })
map("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Find buffers" })
map("n", "<leader>fw", function() Snacks.picker.grep() end, { desc = "Search project text" })
map("n", "<leader>fh", function() Snacks.picker.help() end, { desc = "Search help" })
map("n", "<leader>fc", function() Snacks.picker.commands() end, { desc = "Search commands" })
map("n", "<leader>fr", function() Snacks.picker.recent() end, { desc = "Recent files" })
map("n", "<leader>f.", function() Snacks.picker.resume() end, { desc = "Resume last search" })

-- Terminal: F12 toggles it from normal, insert and terminal mode, 24 rows
-- along the bottom. Set here, not in the `terminal` settings above: those
-- also apply to lazygit (which runs in a snacks terminal) and would pull it
-- out of its floating window.
local function toggle_terminal()
  Snacks.terminal.toggle(nil, { win = { position = "bottom", height = 24 } })
end
map({ "n", "i", "t" }, "<F12>", toggle_terminal, { desc = "Toggle terminal" })

-- lazygit, shown and hidden again with the same process
local function lazygit()
  if vim.fn.executable "lazygit" ~= 1 then
    vim.notify("LazyGit is not installed or is missing from PATH", vim.log.levels.ERROR)
    return
  end
  Snacks.lazygit()
end
map("n", "<leader>gg", lazygit, { desc = "LazyGit" })

-- Close a buffer without closing its window
map("n", "<leader>c", function() Snacks.bufdelete() end, { desc = "Close buffer" })
map("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Close buffer" })

-- stylua: ignore end

vim.api.nvim_create_user_command("Lazygit", lazygit, { desc = "Toggle LazyGit in a floating terminal", force = true })
