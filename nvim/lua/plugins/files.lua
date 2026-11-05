local function build_fzf(path)
  local result = vim.system({ "make" }, { cwd = path, text = true }):wait()
  if result.code ~= 0 then
    error("Failed to build Telescope fzf-native: " .. (result.stderr or result.stdout or ""))
  end
end

-- Build the native sorter when it is installed or updated.
vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("TelescopeFzfBuild", { clear = true }),
  desc = "Build Telescope's fzf-native sorter",
  callback = function(args)
    local event = args.data
    if event.spec.name ~= "telescope-fzf-native.nvim" or event.kind == "delete" then
      return
    end
    build_fzf(event.path)
  end,
})

vim.pack.add {
  "https://github.com/stevearc/oil.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
}

-- Cleanup can remove compiled files without changing the package revision.
local fzf = vim.pack.get({ "telescope-fzf-native.nvim" })[1]
if not vim.uv.fs_stat(vim.fs.joinpath(fzf.path, "build", "libfzf.so")) then
  build_fzf(fzf.path)
end

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

require("nvim-web-devicons").setup {
  override_by_filename = {
    ["tsconfig.json"] = { icon = "󰛦" },
  },
  override_by_extension = {
    tex = { icon = "" },
    cls = { icon = "" },
    sty = { icon = "" },
  },
}

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

--------------------------------------------------------------------------------
------------------------------ Telescope ---------------------------------------
--------------------------------------------------------------------------------
local telescope = require "telescope"

telescope.setup {
  defaults = {
    file_ignore_patterns = { "^%.git/", "/%.git/", "node_modules/", "%.DS_Store$" },
  },
  pickers = {
    find_files = { hidden = true },
    live_grep = { additional_args = { "--hidden" } },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
}

telescope.load_extension "fzf"

local builtin = require "telescope.builtin"

map("n", "<C-p>", builtin.find_files, { desc = "Find files" })
map("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
map("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
map("n", "<leader>fw", builtin.live_grep, { desc = "Search project text" })
map("n", "<leader>fh", builtin.help_tags, { desc = "Search help" })
map("n", "<leader>fc", builtin.commands, { desc = "Search commands" })
