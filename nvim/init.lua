require "config.options"
require "config.keymaps"

-- Set by the zsh config: "essential" on a Raspberry Pi, "full" everywhere else.
local essential = vim.env.NVIM_PROFILE == "essential"

if not vim.g.vscode then
  require "plugins.utils"

  require "plugins.colorscheme"
  require "plugins.editor"
  require "plugins.files"
  require "plugins.git"
  require "plugins.tmux"
  require "plugins.ui"

  if not essential then
    require "plugins.treesitter"
    require "plugins.lsp"
    require "plugins.language-specific.latex"
    require "plugins.language-specific.markdown"
  end
end
