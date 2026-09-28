-- Turn on spell check for these filetypes
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.txt", "*.md", "*.tex" },
  callback = function()
    -- vim.opt.spell = true
    -- vim.opt.spelllang = "hu,en_us,ru"
  end,
})

-- Set the syntax for mdx files to md
-- vim.cmd [[
-- augroup twig_ft
--   au!
--   autocmd BufNewFile,BufRead *.mdx set syntax=md
-- augroup END
