-- Start of config loading, used for the startup time on the welcome screen.
vim.g.start_time = vim.uv.hrtime()

-- Cache compiled Lua modules (lazy.nvim used to enable this automatically).
vim.loader.enable()

require "config.options"
require "config.keymaps"

-- Set by the zsh config: "essential" on a Raspberry Pi, "full" everywhere else.
local essential = vim.env.NVIM_PROFILE == "essential"

if not vim.g.vscode then
  require "plugins.utils"

  require "plugins.colorscheme"
  -- Picker, terminal, lazygit, bufdelete and the welcome screen; before the
  -- files below, which use them
  require "plugins.snacks"
  require "plugins.editor"
  require "plugins.files"
  require "plugins.tmux"

  -- Everything else is loaded right after the first screen is drawn, so the
  -- welcome screen (or a file opened from the command line) shows up sooner
  -- (about 30 ms of the startup time is these). They take a few milliseconds
  -- more to appear; see lua/config/deferred.lua.
  require("config.deferred").after_first_screen(function()
    require "plugins.git"
    require "plugins.ui"

    if not essential then
      require "plugins.treesitter"
      require "plugins.lsp"
      require "plugins.language-specific.latex"
      require "plugins.language-specific.markdown"
    end
  end)
end
