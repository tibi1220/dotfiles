-- VimTeX reads its options while loading filetype plugins.
-- pdfty is VimTeX's viewer (its autoload/vimtex/view/pdfty.vim): <localleader>lv
-- and the first successful compile open the side panel and jump to the cursor.
vim.g.vimtex_view_method = "pdfty"
vim.g.vimtex_compiler_method = "latexmk"
vim.g.vimtex_syntax_enabled = false
vim.g.vimtex_quickfix_ignore_filters = { "Underfull", "Overfull" }

vim.pack.add { "https://github.com/lervag/vimtex" }

-- pdfty: the local PDF previewer, shown in a side panel (or a separate
-- tmux/Kitty pane). Loaded from the checkout, which vim.pack can't install.
local pdfty_dir = vim.fn.expand "~/Documents/Code/pdfty"
local pdfty_present = vim.uv.fs_stat(vim.fs.joinpath(pdfty_dir, "lua", "pdfty", "init.lua")) ~= nil
if pdfty_present then
  vim.opt.runtimepath:append(pdfty_dir)
end
-- Prefer the freshly built binary in the checkout, else `pdfty` on PATH
-- (`cargo install --path ~/Documents/Code/pdfty --force`).
local pdfty_build = vim.fs.joinpath(pdfty_dir, "target", "release", "pdfty")
local pdfty_command = vim.fn.executable(pdfty_build) == 1 and pdfty_build or "pdfty"
local pdfty_loaded = false

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserLatex", { clear = true }),
  pattern = "tex",
  callback = function(args)
    vim.keymap.set("n", "<leader>lj", "<Cmd>cclose<CR>", { buffer = args.buf, desc = "Close errors" })
    vim.keymap.set("n", "<leader>lo", "<Cmd>copen<CR>", { buffer = args.buf, desc = "Open errors" })

    -- Run after VimTeX has installed its buffer-local mappings.
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        pcall(vim.keymap.del, "i", "]]", { buffer = args.buf })
      end
    end)

    if not pdfty_loaded and pdfty_present then
      require("pdfty").setup {
        command = pdfty_command,
        auto_register = true,
        register_interval = 5000,
        notifications = true,
        -- Jump to the cursor's paragraph after every successful compile.
        follow = { on_compile = true, on_cursor_hold = false },
        compile_status = true,
        dark_pages = false,
        keymaps = {
          toggle = "<leader>pv",
          focus = "<leader>po",
          outline = "<leader>ps",
          dark = "<leader>pd",
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
          live = "<leader>pl",
        },
        live = {
          enabled = false,
          delay = 200,
        },
        terminal = {
          -- Inside tmux the viewer gets its own tmux pane; elsewhere it runs
          -- in a split inside Neovim.
          provider = (vim.env.TMUX and vim.env.TMUX ~= "") and "tmux" or "panel",
          split_side = "right",
          split_width_percentage = 0.40,
        },
      }
      pdfty_loaded = true
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
