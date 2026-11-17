-- Every plugin, installed and registered with one vim.pack.add: vim.pack
-- reads and writes its lockfile once, instead of once per plugin file.
--
-- When a plugin is loaded doesn't change:
--   * startup plugins go on the runtimepath now, and Neovim sources their
--     plugin/ files once init.lua is done (like a vim.pack.add in each file);
--   * deferred plugins (see init.lua and config/deferred.lua) are only
--     registered here. Their file loads them after the first screen with
--     require("plugins").load(name), right after setting any options the
--     plugin reads while loading (VimTeX's g:vimtex_*).
--
-- The essential profile (Raspberry Pi) doesn't install the plugins it never
-- loads.

local M = {}

local essential = vim.env.NVIM_PROFILE == "essential"
local range = vim.version.range

-- Loaded at startup
local startup = {
  -- utils.lua
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/nvim-mini/mini.pairs",
  "https://github.com/folke/persistence.nvim",
  -- colorscheme.lua
  "https://github.com/EdenEast/nightfox.nvim",
  -- snacks.lua
  { src = "https://github.com/folke/snacks.nvim", version = range "2" },
  -- editor.lua
  { src = "https://github.com/akinsho/bufferline.nvim", version = range "4" },
  "https://github.com/nvim-lualine/lualine.nvim",
  "https://github.com/folke/which-key.nvim",
  -- files.lua (plenary and nui are needed by neo-tree)
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
  -- tmux.lua
  "https://github.com/christoomey/vim-tmux-navigator",
}

-- Loaded after the first screen, by the file named
local deferred = {
  -- git.lua
  "https://github.com/lewis6991/gitsigns.nvim",
  -- ui.lua
  "https://github.com/catgoose/nvim-colorizer.lua",
  "https://github.com/nvim-mini/mini.indentscope",
  "https://github.com/lewis6991/satellite.nvim",
}

-- Deferred, and not in the essential profile
local full = {
  -- treesitter.lua
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  -- lsp.lua
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/rafamadriz/friendly-snippets",
  "https://github.com/folke/lazydev.nvim",
  "https://github.com/stevearc/conform.nvim",
  -- Release tags support automatic download of the Rust fuzzy matcher.
  { src = "https://github.com/saghen/blink.cmp", version = range "1" },
  -- language-specific/latex.lua
  "https://github.com/lervag/vimtex",
  -- language-specific/markdown.lua
  "https://github.com/brianhuster/live-preview.nvim",
  -- ai.lua
  "https://github.com/coder/claudecode.nvim",
}

local specs, later = {}, {}
local function collect(list, is_deferred)
  for _, spec in ipairs(list) do
    specs[#specs + 1] = spec
    if is_deferred then
      local src = type(spec) == "table" and spec.src or spec
      later[src:match "[^/]+$"] = true
    end
  end
end
collect(startup, false)
collect(deferred, true)
if not essential then
  collect(full, true)
end

vim.pack.add(specs, {
  load = function(plugin)
    if not later[plugin.spec.name] then
      vim.cmd.packadd { plugin.spec.name, bang = true }
    end
  end,
})

-- Load a deferred plugin (its plugin/ files run now)
function M.load(...)
  for _, name in ipairs { ... } do
    vim.cmd.packadd(name)
  end
end

return M
