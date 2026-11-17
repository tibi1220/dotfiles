-- The F12 terminal and closing buffers (<leader>c) are snacks.nvim: see
-- snacks.lua.
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
-- window's statusline (disabled_filetypes doesn't stop that): the :Trains
-- strip keeps its own, empty one
do
  local opts = require "lualine.utils.nvim_opts"
  local set = opts.set
  opts.set = function(name, val, scope)
    local win = scope and scope.window
    if
      name == "statusline"
      and win
      and vim.api.nvim_win_is_valid(win)
      and vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "locktrains"
    then
      return
    end
    return set(name, val, scope)
  end
end
