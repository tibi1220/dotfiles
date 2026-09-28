require "config.options"

if vim.g.vscode then
  require "config.vscode"
else
  require "config.lazy"
  require "config.keymaps"
  require "config.autocmds"
end
