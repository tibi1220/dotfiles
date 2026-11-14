-- Fuzzy finding (files, text, buffers, ...) is snacks.picker: see snacks.lua.

vim.pack.add {
  -- plenary and nui are needed by neo-tree
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
}

local map = vim.keymap.set

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
