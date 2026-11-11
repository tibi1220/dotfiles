-- Fuzzy finding (files, text, buffers, ...) is snacks.picker: see snacks.lua.

vim.pack.add {
  "https://github.com/stevearc/oil.nvim",
  -- plenary and nui are needed by neo-tree
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
}

local map = vim.keymap.set

--------------------------------------------------------------------------------
------------------------------ Oil ---------------------------------------------
--------------------------------------------------------------------------------
local oil = require "oil"

oil.setup {
  -- Use Oil for directory buffers without requiring an icon plugin.
  default_file_explorer = true,
  columns = {
    "icon",
  },
  view_options = {
    show_hidden = true,
    is_always_hidden = function(name)
      return name == ".DS_Store"
    end,
  },
  win_options = {
    number = false,
    relativenumber = false,
    colorcolumn = "",
  },
  keymaps = {
    -- Keep Ctrl-h and Ctrl-l available for Neovim/tmux navigation.
    ["<C-h>"] = false,
    ["<C-l>"] = false,
    ["<C-x>"] = { "actions.select", opts = { horizontal = true } },
    ["gr"] = "actions.refresh",
  },
  float = {
    border = "rounded",
  },
}

map("n", "-", oil.open, { desc = "Open parent directory" })
map("n", "<leader>e", oil.open_float, { desc = "Open file explorer in floating window" })

--------------------------------------------------------------------------------
------------------------------ File tree ---------------------------------------
--------------------------------------------------------------------------------
vim.g.neo_tree_remove_legacy_commands = 1

require("neo-tree").setup {
  window = {
    width = 32,
  },
  filesystem = {
    follow_current_file = {
      enabled = true,
    },
    bind_to_cwd = false,
    filtered_items = {
      hide_dotfiles = false,
      hide_hidden = false,
      show_hidden_count = false,
      hide_gitignored = false,
    },
  },
  default_component_configs = {
    indent = {
      with_expanders = true,
      expander_collapsed = "",
      expander_expanded = "",
      expander_highlight = "NeoTreeExpander",
    },
  },
}

map("n", "<C-b>", "<Cmd>Neotree toggle<CR>", { desc = "Toggle NeoTree" })
map("n", "<C-c>", "<Cmd>Neotree close<CR>", { desc = "Close NeoTree" })
map("n", "<C-g>", "<Cmd>Neotree focus<CR>", { desc = "Focus NeoTree" })
map("n", "<leader>ft", "<Cmd>Neotree float<CR>", { desc = "Float NeoTree" })
