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

-- Colors, as on the previous (alpha) welcome screen. default = true lets a
-- colorscheme that styles the dashboard itself win.
local function dashboard_highlights()
  for name, target in pairs {
    SnacksDashboardHeader = "Type",
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

  terminal = {
    win = { position = "bottom", height = 24 },
  },

  lazygit = {
    -- Edit files in this Neovim (lazygit's `e` closes the float and opens
    -- the file here) and use the theme above
    configure = true,
    config = { gui = { theme = lazygit_theme } },
  },

  bufdelete = { enabled = true },

  dashboard = {
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
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = {
      { section = "header", padding = 2 },
      { section = "keys", gap = 1, padding = 1 },
      footer,
    },
  },

  -- Image viewer: opening an image (png, jpg, gif, webp, pdf, ...) shows it
  -- in the buffer, and images / LaTeX math in Markdown are rendered inline.
  -- Needs a terminal with the kitty graphics protocol (kitty, Ghostty,
  -- WezTerm; through tmux with `allow-passthrough on`) and ImageMagick.
  -- Ghostscript is used for PDFs, pdflatex/tectonic for math. Check with
  -- :checkhealth snacks.
  image = { enabled = not essential },
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

-- Terminal: F12 toggles it from normal, insert and terminal mode
map({ "n", "i", "t" }, "<F12>", function() Snacks.terminal.toggle() end, { desc = "Toggle terminal" })

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
