return {
  -----------------------------------------------------------------------------
  -- TeX ----------------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "lervag/vimtex",
    lazy = false,
    init = function()
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_compiler_method = "latexmk"
      -- latexmk runs from VimTeX's main-file directory. Let the project's
      -- .latexmkrc choose the engine, just as the VS Code recipe does.
      vim.g.vimtex_compiler_latexmk_engines = { _ = "" }
      vim.g.vimtex_compiler_latexmk = {
        out_dir = "build",
        continuous = 0,
        options = { "-norc", "-r", ".latexmkrc" },
      }
      vim.g.vimtex_syntax_enabled = false -- Keep Tree-sitter highlighting for embedded Lua.
      vim.g.vimtex_mappings_disable = { i = { "]]" } }
      vim.g.vimtex_quickfix_ignore_filters = { "Underfull", "Overfull" }
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("VimtexConfig", { clear = true }),
        pattern = "tex",
        callback = function()
          vim.fn.writefile({ vim.v.servername }, "/tmp/vimtexserver.txt")
        end,
      })
    end,
    -- Skim command
    -- nvr --servername `cat /tmp/vimtexserver.txt` +"%line" "%file"
    -- stylua: ignore
    keys = {
      { "<SPACE>lj", "<CMD>cclose<CR>", mode = "n", desc = "Close errors" },
      { "<SPACE>lo", "<CMD>copen<CR>", mode = "n", desc = "Open errors" },
    },
  },

  -----------------------------------------------------------------------------
  -- Markdown -----------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = ":call mkdp#util#install_sync()",
  },
}
