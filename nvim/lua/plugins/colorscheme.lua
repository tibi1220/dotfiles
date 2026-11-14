vim.pack.add { "https://github.com/EdenEast/nightfox.nvim" }

require("nightfox").setup {
  options = {
    -- Comments and the language's own words in italic; names stay upright.
    -- keywords: return, local, nil, ...; conditionals: if, else, for, while
    styles = {
      comments = "italic",
      keywords = "italic,bold",
      conditionals = "italic",
    },
  },
  groups = {
    all = {
      -- `function` / `def` / `func` follow the `functions` style, which
      -- would also make every function name italic: style them as keywords
      ["@keyword.function"] = { link = "Keyword" },
      EndOfBuffer = { fg = "#738091", bg = "NONE" },
    },
  },
}

vim.cmd.colorscheme "nightfox"
