return {
  -----------------------------------------------------------------------------
  -- nvim-colorizer -----------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = {
      filetypes = { "*" },
      options = {
        parsers = {
          hex = {
            default = false,
            rgb = true, -- #RGB
            rrggbb = true, -- #RRGGBB
            rrggbbaa = true, -- #RRGGBBAA
          },
        },
      },
    },
    config = function(_, opts)
      require("colorizer").setup(opts)
    end,
  },

  -----------------------------------------------------------------------------
  -- nvim-notify --------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "rcarriga/nvim-notify",
    init = function()
      vim.notify = require "notify"
    end,
  },

  -----------------------------------------------------------------------------
  -- Noice --------------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "folke/noice.nvim",
    enabled = false,
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      cmdline = {
        view = "cmdline",
        format = {
          cmdline = false,
          search_down = false,
          search_up = false,
          filter = false,
          lua = false,
          help = false,
          input = false,
        },
      },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
        signature = {
          enabled = false,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
      },
    },
    -- stylua: ignore
    keys = {
      { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline" },
      { "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
      { "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History" },
      { "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All" },
      { "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All" },
      { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "Scroll forward", mode = {"i", "n", "s"} },
      { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "Scroll backward", mode = {"i", "n", "s"}},
    },
  },

  -----------------------------------------------------------------------------
  -- Indent Blankline ---------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = function()
      vim.opt.list = true
      vim.opt.listchars:append "eol:↴"
      -- vim.opt.listchars:append "space:─" -- ◦ ▁ ⋅ ─

      return {
        indent = { char = "▏" }, -- │▏├
        exclude = { filetypes = { "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy" } },
        -- show_trailing_blankline_indent = false,
        -- show_current_context = false,
        -- char_highlight_list = {
        --   "IndentBlanklineIndent1",
        --   "IndentBlanklineIndent2",
        --   "IndentBlanklineIndent3",
        --   "IndentBlanklineIndent4",
        --   "IndentBlanklineIndent5",
        --   "IndentBlanklineIndent6",
        -- },
        -- char_highlight_list = {
        --   "IndentBlanklineIndent7",
        --   "IndentBlanklineIndent8",
        -- },
        -- space_char_highlight_list = {
        --   "IndentBlanklineIndent7",
        --   "IndentBlanklineIndent8",
        -- },
      }
    end,
  },
  -----------------------------------------------------------------------------
  -- Mini Indentoscope --------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "nvim-mini/mini.indentscope",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      symbol = "▍", --┃▏▎▍┣╟
      options = { try_as_border = true },
    },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy", "mason" },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
    config = function(_, opts)
      require("mini.indentscope").setup(opts)
    end,
  },
  -----------------------------------------------------------------------------
  -- Alpha --------------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    opts = function()
      local dashboard = require "alpha.themes.dashboard"
      local logo = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
      ]]

      dashboard.section.header.val = vim.split(logo, "\n")
      dashboard.section.buttons.val = {
        dashboard.button("f", " " .. " Find file", "<CMD>Telescope find_files <CR>"),
        dashboard.button("e", " " .. " New file", "<CMD>ene <BAR> startinsert <CR>"),
        dashboard.button("r", " " .. " Recent files", "<CMD>Telescope oldfiles <CR>"),
        dashboard.button("w", " " .. " Find text", "<CMD>Telescope live_grep <CR>"),
        dashboard.button("c", " " .. " Config", ":e $MYVIMRC <CR>"),
        dashboard.button("s", " " .. " Restore Session", [[:lua require("persistence").load() <cr>]]),
        dashboard.button("l", "󰒲 " .. " Lazy", "<CMD>Lazy<CR>"),
        dashboard.button("q", " " .. " Quit", "<CMD>qa<CR>"),
      }
      for _, button in ipairs(dashboard.section.buttons.val) do
        button.opts.hl = "AlphaButtons"
        button.opts.hl_shortcut = "AlphaShortcut"
      end
      dashboard.section.header.opts.hl = "AlphaHeader"
      dashboard.section.buttons.opts.hl = "AlphaButtons"
      dashboard.section.footer.opts.hl = "AlphaFooter"
      dashboard.opts.layout[1].val = 8
      return dashboard
    end,
    config = function(_, dashboard)
      local lazy = require "lazy"

      -- close Lazy and re-open when the dashboard is ready
      if vim.o.filetype == "lazy" then
        vim.cmd.close()
        vim.api.nvim_create_autocmd("User", {
          pattern = "AlphaReady",
          callback = function()
            lazy.show()
          end,
        })
      end

      require("alpha").setup(dashboard.opts)

      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimStarted",
        callback = function()
          local stats = lazy.stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          dashboard.section.footer.val = "⚡ Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms"
          pcall(vim.cmd.AlphaRedraw)
        end,
      })
    end,
  },
}
