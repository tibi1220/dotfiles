return {
  -----------------------------------------------------------------------------
  -- TeX ----------------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "lervag/vimtex",
    ft = "tex",
    -- enabled = false,
    -- lazy = false,
    config = function()
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_syntax_enabled = false -- Fucks up lua code
      vim.g.vimtex_quickfix_ignore_filters = {
        "Underfull",
        "Overfull",
      }

      vim.cmd [[
      function! s:write_server_name() abort
      let nvim_server_file = (has('win32') ? $TEMP : '/tmp') . '/vimtexserver.txt'
      call writefile([v:servername], nvim_server_file)
      endfunction

      augroup vimtex_common
        autocmd!
        autocmd FileType tex call s:write_server_name()
      augroup END

      " let g:vimtex_quickfix_ignore_filters = [
      "   \ 'underline',
      "   \ 'underbar',
      "   \ 'Underfull',
      "   \ 'Overfull',
      "   \ 'bad break',
      "   \ 'Font',
      "   \ 'Label',
      " \]
]]

      -- A not so elegant way to remove this mapping
      vim.cmd "autocmd FileType tex iunmap <buffer> ]]"
    end,
    -- Skim command
    -- nvr --servername `cat /tmp/vimtexserver.txt` +"%line" "%file"
    -- stylua: ignore
    keys = {
      { "<SPACE>lj", "<CMD>cclose<CR>", mode = "n", desc = "Close errors" },
      { "<SPACE>lo", "<CMD>copen<CR>", mode = "n", desc = "Open errors" },
    },
  },

  {
    dir = vim.fn.expand "/Users/tiborsandor/Documents/Code/pdfty",
    name = "pdfty",
    main = "pdfty",
    ft = { "tex" },
    build = "cargo install --path . --force",
    opts = {
      command = "pdfty",
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
      },
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
