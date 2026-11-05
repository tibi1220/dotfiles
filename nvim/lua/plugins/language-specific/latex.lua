-- VimTeX reads its options while loading filetype plugins.
vim.g.vimtex_view_method = "skim"
vim.g.vimtex_compiler_method = "latexmk"
vim.g.vimtex_syntax_enabled = false
vim.g.vimtex_quickfix_ignore_filters = { "Underfull", "Overfull" }

vim.pack.add { "https://github.com/lervag/vimtex" }

-- Keep the existing local PDF viewer integration.
local cdfty_dir = vim.fn.expand "~/Documents/Code/cdfty"
if vim.uv.fs_stat(vim.fs.joinpath(cdfty_dir, "lua", "cdfty", "init.lua")) then
  vim.opt.runtimepath:append(cdfty_dir)
end
local cdfty_loaded = false

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserLatex", { clear = true }),
  pattern = "tex",
  callback = function(args)
    -- Preserve the server-name file used by Skim's existing inverse-search command.
    local server_file = vim.fn.has "win32" == 1 and vim.fs.joinpath(vim.fn.stdpath "run", "vimtexserver.txt")
      or "/tmp/vimtexserver.txt"
    vim.fn.writefile({ vim.v.servername }, server_file)

    vim.keymap.set("n", "<leader>lj", "<Cmd>cclose<CR>", { buffer = args.buf, desc = "Close errors" })
    vim.keymap.set("n", "<leader>lo", "<Cmd>copen<CR>", { buffer = args.buf, desc = "Open errors" })

    -- Run after VimTeX has installed its buffer-local mappings.
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        pcall(vim.keymap.del, "i", "]]", { buffer = args.buf })
      end
    end)

    if not cdfty_loaded and vim.uv.fs_stat(vim.fs.joinpath(cdfty_dir, "lua", "cdfty", "init.lua")) then
      require("cdfty").setup {
        command = vim.fs.joinpath(cdfty_dir, "build", "cdfty"),
        auto_register = true,
        register_interval = 5000,
        notifications = true,
        keymaps = {
          add = "<leader>pa",
          forward = "<leader>pf",
          next = "<leader>pj",
          prev = "<leader>pk",
          move = "<leader>pm",
          switch = "<leader>pp",
          zoom_in = "<leader>p+",
          zoom_out = "<leader>p-",
          view = "<leader>pt",
          center = "<leader>pc",
          clear = "<leader>ph",
        },
      }
      cdfty_loaded = true
    end
  end,
})

-- Preserve project-local latexindent configuration from the old LSP setup.
local conform = require "conform"
conform.formatters_by_ft.bib = { "latexindent" }
conform.formatters.latexindent = {
  prepend_args = function(_, ctx)
    local file = vim.api.nvim_buf_get_name(ctx.buf)
    local dir = vim.fs.dirname(file)
    local root_dir = vim.b[ctx.buf].vimtex and vim.b[ctx.buf].vimtex.root or dir
    return { "-l=" .. vim.fs.joinpath(root_dir, ".latexindent.yaml"), "-c=" .. dir }
  end,
}
