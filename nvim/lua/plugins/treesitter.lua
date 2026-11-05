local parsers = {
  "bash",
  "c",
  "cpp",
  "objc",
  "css",
  "html",
  "javascript",
  "json",
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

local function highlight(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return
  end
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  -- LaTeX keeps its existing VimTeX setup; only enable the selected languages.
  if not lang or not vim.tbl_contains(parsers, lang) then
    return
  end
  if pcall(vim.treesitter.language.add, lang) then
    vim.treesitter.start(buf, lang)
  end
end

local function after_install(err)
  vim.schedule(function()
    if err then
      vim.notify("Tree-sitter parser installation failed: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    -- Activate highlighting in buffers opened while parsers were installing.
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      highlight(buf)
    end
  end)
end

vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("TreesitterUpdate", { clear = true }),
  desc = "Update parsers when nvim-treesitter is updated",
  callback = function(args)
    if args.data.spec.name == "nvim-treesitter" and args.data.kind == "update" then
      vim.schedule(function()
        require("nvim-treesitter").update(parsers):await(after_install)
      end)
    end
  end,
})

vim.pack.add {
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
}

local treesitter = require "nvim-treesitter"
treesitter.setup {}

-- The JSON grammar also supports comments.
vim.treesitter.language.register("json", "jsonc")

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true }),
  desc = "Enable Tree-sitter highlighting for supported file buffers",
  callback = function(args)
    highlight(args.buf)
  end,
})

-- Installation is asynchronous and skips parsers that are already installed.
-- Indentation and folding keep their existing settings.
treesitter.install(parsers):await(after_install)
