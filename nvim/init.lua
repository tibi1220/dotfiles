require "config.options"
require "config.keymaps"

if not vim.g.vscode then
  require "plugins.utils"

  require "plugins.colorscheme"
  require "plugins.treesitter"
  require "plugins.editor"
  require "plugins.files"
  require "plugins.git"
  require "plugins.lsp"
  require "plugins.language-specific.latex"
  require "plugins.language-specific.markdown"
  require "plugins.tmux"
  require "plugins.ui"
end
