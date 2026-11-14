-- The F12 terminal and closing buffers (<leader>c) are snacks.nvim: see
-- snacks.lua.
vim.pack.add {
  { src = "https://github.com/akinsho/bufferline.nvim", version = vim.version.range "4" },
  "https://github.com/nvim-mini/mini.map",
  "https://github.com/nvim-lualine/lualine.nvim",
  "https://github.com/folke/which-key.nvim",
}

local map = vim.keymap.set

--------------------------------------------------------------------------------
------------------------------ Keymap hints ------------------------------------
--------------------------------------------------------------------------------
-- After a prefix key (<leader>, g, z, ], ", ...), which-key shows the keys
-- that can follow, with their descriptions
local which_key = require "which-key"

which_key.setup {
  spec = {
    -- Names for the <leader> groups. <leader>c, <leader>p and <leader>y
    -- are also mappings of their own (close buffer, paste, copy).
    { "<leader>a", group = "Claude Code" },
    { "<leader>b", group = "buffer" },
    { "<leader>c", group = "code" },
    { "<leader>f", group = "find" },
    { "<leader>g", group = "git" },
    { "<leader>m", group = "minimap" },
    { "<leader>q", group = "session" },
    { "<leader>t", group = "toggle" },
    { "<leader>y", group = "clipboard" },
  },
}

-- The LaTeX keys (language-specific/latex.lua) exist only in .tex buffers;
-- elsewhere <leader>p is just "paste"
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("WhichKeyLatex", { clear = true }),
  pattern = "tex",
  desc = "Name the LaTeX key groups",
  callback = function(args)
    which_key.add {
      { "<leader>l", group = "LaTeX errors", buffer = args.buf },
      { "<leader>p", group = "PDF viewer", buffer = args.buf },
    }
  end,
})

map("n", "<leader>?", function()
  which_key.show { global = false }
end, { desc = "Keymaps of this buffer" })

--------------------------------------------------------------------------------
------------------------------ Tabline -----------------------------------------
--------------------------------------------------------------------------------
require("bufferline").setup {
  options = {
    -- Close a buffer without closing its window
    close_command = function(buf)
      Snacks.bufdelete { buf = buf, force = true }
    end,
    -- Each tab as wide as its name (tab_size is the width shorter tabs get
    -- padded to), with names cut off after max_name_length characters
    tab_size = 0,
    max_name_length = 20,
    max_prefix_length = 15,
    diagnostics = "nvim_lsp",
    separator_style = { "▏", "▕" },
    show_close_icon = false,
    offsets = {
      {
        filetype = "neo-tree",
        text = " ----- File Explorer ----- ",
        highlight = "Directory",
        text_align = "left",
      },
    },
  },
}

map("n", "<S-l>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Go to next buffer" })
map("n", "<S-h>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Go to prev buffer" })

--------------------------------------------------------------------------------
------------------------------ Minimap -----------------------------------------
--------------------------------------------------------------------------------
local minimap = require "mini.map"

map("n", "<leader>mc", minimap.close, { desc = "Close minimap" })
map("n", "<leader>mf", minimap.toggle_focus, { desc = "Focus minimap" })
map("n", "<leader>mo", minimap.open, { desc = "Open minimap" })
map("n", "<leader>mr", minimap.refresh, { desc = "Refresh minimap" })
map("n", "<leader>ms", minimap.toggle_side, { desc = "Toggle minimap side" })
map("n", "<leader>mt", minimap.toggle, { desc = "Toggle minimap" })

minimap.setup {
  integrations = {
    minimap.gen_integration.diagnostic {
      error = "DiagnosticFloatingError",
      warn = "DiagnosticFloatingWarn",
      info = "DiagnosticFloatingInfo",
      hint = "DiagnosticFloatingHint",
    },
    minimap.gen_integration.gitsigns(),
    minimap.gen_integration.builtin_search(),
  },
  symbols = {
    encode = minimap.gen_encode_symbols.dot "4x2",
    scroll_line = "▶",
    scroll_view = "┋",
  },
  window = {
    side = "right",
    width = 12,
    winblend = 0,
    show_integration_count = true,
  },
}

-- The minimap is a floating window at the screen's right edge. mini.map has
-- no options for where else to put it, so its (internal) window placement
-- is wrapped:
--   * :Trains keeps the screen's first rows for its strip (lua/locktrains/
--     strip.lua): the minimap starts below them.
--   * The Claude Code panel (plugins/ai.lua) and the pdfty PDF panel
--     (language-specific/latex.lua) are splits along the right edge: the
--     minimap goes left of them instead of on top of them.

-- Filetypes of the side panels the minimap must not cover
local right_panels = { claudecode = true, pdfty = true }

-- Columns taken by side panels along the screen's right edge (with the
-- separator before them). Panels can sit next to each other (Claude beside
-- the PDF), so walk leftwards from the edge through adjacent panels.
local function right_panel_columns()
  local panels = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if
      vim.api.nvim_win_get_config(win).relative == ""
      and right_panels[vim.bo[vim.api.nvim_win_get_buf(win)].filetype]
    then
      local col = vim.api.nvim_win_get_position(win)[2]
      table.insert(panels, { left = col, right = col + vim.api.nvim_win_get_width(win) })
    end
  end
  local edge = vim.o.columns
  local moved = true
  while moved do
    moved = false
    for _, panel in ipairs(panels) do
      -- A panel reaches the edge if its right side (plus a separator) does
      if panel.left < edge and panel.right + 1 >= edge then
        edge = panel.left
        moved = true
      end
    end
  end
  return edge < vim.o.columns and vim.o.columns - edge + 1 or 0
end

do
  local H
  for i = 1, 64 do
    local name, value = debug.getupvalue(MiniMap.refresh, i)
    if not name then
      break
    end
    if name == "H" then
      H = value
      break
    end
  end
  if H and H.normalize_window_options then
    local normalize = H.normalize_window_options
    H.normalize_window_options = function(...)
      local config = normalize(...)
      local top = package.loaded["locktrains.strip"] and require("locktrains.strip").top_rows() or 0
      if top > config.row then
        config.height = math.max(1, config.height - (top - config.row))
        config.row = top
      end
      if config.anchor == "NE" then
        config.col = config.col - right_panel_columns()
      end
      return config
    end
  end
end

-- Place the minimap again when the windows change (a side panel opens,
-- closes or is resized)
vim.api.nvim_create_autocmd({ "WinNew", "WinClosed", "WinResized", "VimResized" }, {
  group = vim.api.nvim_create_augroup("MiniMapPlacement", { clear = true }),
  desc = "Keep the minimap clear of the side panels",
  callback = function()
    vim.schedule(function()
      if MiniMap.current.win_data[vim.api.nvim_get_current_tabpage()] then
        pcall(MiniMap.refresh, {}, { integrations = false, lines = false, scrollbar = false })
      end
    end)
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = "MiniMapPlacement",
  pattern = { "claudecode", "pdfty" },
  desc = "Keep the minimap clear of the side panels",
  callback = function()
    vim.schedule(function()
      pcall(MiniMap.refresh, {}, { integrations = false, lines = false, scrollbar = false })
    end)
  end,
})

local function is_explorer_buffer(buf)
  return vim.bo[buf].filetype == "neo-tree"
end

local function is_file_buffer(buf)
  return vim.api.nvim_buf_is_valid(buf)
    and not is_explorer_buffer(buf)
    and vim.bo[buf].buftype == ""
    and vim.api.nvim_buf_get_name(buf) ~= ""
end

vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  group = vim.api.nvim_create_augroup("MiniMapAutoOpen", { clear = true }),
  desc = "Open mini.map for file buffers and hide it in file explorers",
  callback = function(args)
    if is_explorer_buffer(args.buf) then
      minimap.close()
    elseif is_file_buffer(args.buf) then
      minimap.open()
    end
  end,
})

--------------------------------------------------------------------------------
------------------------------ Statusline --------------------------------------
--------------------------------------------------------------------------------
local lualine = require "lualine"

lualine.setup {
  extensions = { "neo-tree" },
  options = {
    theme = "nightfox",
    icons_enabled = true,
    component_separators = "",
    section_separators = "",
    always_divide_middle = true,
    globalstatus = true,
  },
  sections = {
    lualine_a = {},
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = {
      { "filename", path = 1 },
      {
        function()
          local names = {}
          for _, client in ipairs(vim.lsp.get_clients { bufnr = 0 }) do
            names[#names + 1] = client.name
          end
          table.sort(names)
          return table.concat(names, ", ")
        end,
        icon = " LSP:",
      },
    },
    lualine_x = { "encoding", "fileformat", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { "filename" },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {},
  },
  tabline = {},
}

-- With globalstatus, lualine writes the focused window's bar into every
-- window's statusline (disabled_filetypes doesn't stop that).
--   * The :Trains strip keeps its own, empty one.
--   * In tmux (laststatus=0, the bar is in tmux's status line, see below)
--     Neovim still draws a status row under a window that has another one
--     below it (e.g. above the F12 terminal), which would repeat the bar
--     there. There the bar goes straight to Tpipeline instead, and windows
--     get an empty statusline, drawn as a line like the window separators
--     outside tmux. "%#StatusLine#" is the value Tpipeline ignores when it
--     looks for lualine's bar in the current window.
local tmux_rows = "%#StatusLine#"
do
  local opts = require "lualine.utils.nvim_opts"
  local set = opts.set
  local last_bar
  opts.set = function(name, val, scope)
    local win = scope and scope.window
    if name == "statusline" and win and vim.api.nvim_win_is_valid(win) then
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "locktrains" then
        return
      end
      if vim.o.laststatus == 0 and vim.g.loaded_tpipeline then
        if val and val ~= last_bar then
          last_bar = val
          vim.g.tpipeline_statusline = val
          pcall(vim.fn["tpipeline#update"])
        end
        val = tmux_rows
      end
    end
    return set(name, val, scope)
  end
end

-- The Nightfox tmux theme embeds the exported statusline itself.
-- Set these before loading Tpipeline so it preserves that theme's layout.
vim.g.tpipeline_autoembed = 0
vim.g.tpipeline_split = 1
vim.g.tpipeline_restore = 0

if vim.env.TMUX and vim.env.TMUX_PANE then
  -- Keep generating the statusline for Tpipeline without showing a second bar.
  vim.opt.laststatus = 0
  vim.opt.showmode = false

  -- The status rows between stacked windows (see the lualine wrapper
  -- above): a line in the window separators' color, as outside tmux
  vim.opt.fillchars:append { stl = "─", stlnc = "─" }
  local function separator_rows()
    vim.api.nvim_set_hl(0, "StatusLine", { link = "WinSeparator" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { link = "WinSeparator" })
  end
  separator_rows()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("TmuxSeparatorRows", { clear = true }),
    desc = "Draw the status rows between windows as separators",
    callback = separator_rows,
  })

  -- Tpipeline starts its background job on VimEnter and drops the first bar
  -- if it comes before the job is ready (and then skips it as unchanged):
  -- send it again shortly after, so tmux shows it before the first keypress
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("TmuxFirstBar", { clear = true }),
    once = true,
    desc = "Send lualine's first bar to tmux",
    callback = function()
      vim.defer_fn(function()
        require("lualine").refresh { scope = "all", place = { "statusline" } }
        pcall(vim.fn["tpipeline#forceupdate"])
      end, 300)
    end,
  })

  local pane = vim.env.TMUX_PANE
  local last_style

  local function hex(color)
    return color and string.format("#%06x", color) or nil
  end

  local function publish_mode_colors()
    local suffix = require("lualine.highlight").get_mode_suffix()
    local hl = vim.api.nvim_get_hl(0, {
      name = "lualine_a" .. suffix,
      link = false,
    })
    local fg, bg = hex(hl.fg), hex(hl.bg)
    if not fg or not bg then
      return
    end
    local style = fg .. ":" .. bg
    if style == last_style then
      return
    end
    last_style = style

    vim.system {
      "tmux",
      "set-option",
      "-t",
      pane,
      "@nvim_mode_fg",
      fg,
      ";",
      "set-option",
      "-t",
      pane,
      "@nvim_mode_bg",
      bg,
      ";",
      "refresh-client",
      "-S",
    }
  end

  vim.api.nvim_create_autocmd({ "ModeChanged", "FocusGained", "ColorScheme" }, {
    group = vim.api.nvim_create_augroup("TmuxLualineModeColors", { clear = true }),
    desc = "Share Lualine mode colors with tmux",
    callback = function()
      vim.schedule(publish_mode_colors)
    end,
  })

  vim.schedule(publish_mode_colors)
end

vim.pack.add { "https://github.com/vimpostor/vim-tpipeline" }
