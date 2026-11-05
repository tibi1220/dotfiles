local M = {}

M.parsers = {
  "bash",
  "c",
  "css",
  "html",
  "javascript",
  "json",
  "latex",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "regex",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
}

function M.setup()
  local treesitter = require "nvim-treesitter"
  treesitter.setup {}

  local function attach(buf)
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
      return
    end
    local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
    local ok, available = pcall(vim.treesitter.language.add, lang or "")
    if not lang or not ok or not available then
      return
    end
    vim.treesitter.start(buf, lang)
    if vim.bo[buf].filetype ~= "tex" and vim.treesitter.query.get(lang, "indents") then
      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
    callback = function(event)
      attach(event.buf)
    end,
  })

  -- Installing is a no-op for parsers already present. Attach open buffers after
  -- first-time installation so highlighting doesn't require restarting Neovim.
  if vim.fn.executable "tree-sitter" == 1 then
    treesitter.install(M.parsers):await(function(err)
      vim.schedule(function()
        if err then
          vim.notify("Tree-sitter installation failed: " .. tostring(err), vim.log.levels.ERROR)
          return
        end
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          attach(buf)
        end
      end)
    end)
  else
    vim.schedule(function()
      vim.notify("Install tree-sitter-cli to install/update syntax parsers (see README).", vim.log.levels.WARN)
    end)
  end
end

return M
