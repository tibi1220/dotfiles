-- The F12 terminal and closing buffers (<leader>c) are snacks.nvim: see
-- snacks.lua.
vim.pack.add {
  { src = "https://github.com/akinsho/bufferline.nvim", version = vim.version.range "4" },
  "https://github.com/nvim-mini/mini.map",
  "https://github.com/nvim-lualine/lualine.nvim",
}

local map = vim.keymap.set

--------------------------------------------------------------------------------
------------------------------ Tabline -----------------------------------------
--------------------------------------------------------------------------------
require("bufferline").setup {
  options = {
    -- Close a buffer without closing its window
    close_command = function(buf)
      Snacks.bufdelete { buf = buf, force = true }
    end,
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

local function is_explorer_buffer(buf)
  return vim.bo[buf].filetype == "oil"
    or vim.bo[buf].filetype == "neo-tree"
    or vim.api.nvim_buf_get_name(buf):match "^oil[^:]*://" ~= nil
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

-- The Nightfox tmux theme embeds the exported statusline itself.
-- Set these before loading Tpipeline so it preserves that theme's layout.
vim.g.tpipeline_autoembed = 0
vim.g.tpipeline_split = 1
vim.g.tpipeline_restore = 0

if vim.env.TMUX and vim.env.TMUX_PANE then
  -- Keep generating the statusline for Tpipeline without showing a second bar.
  vim.opt.laststatus = 0
  vim.opt.showmode = false

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
