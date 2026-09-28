return {
  { "nacro90/numb.nvim", event = "VeryLazy", config = true },
  -----------------------------------------------------------------------------
  -- Snippets -----------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "L3MON4D3/LuaSnip",
    build = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function(_, opts)
      require("luasnip").config.setup(opts)
      require("luasnip.loaders.from_vscode").load { paths = vim.fn.stdpath "config" .. "/lua/snippets" }
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
    opts = {
      history = true,
      delete_check_events = "TextChanged",
    },
    -- stylua: ignore
    keys = {
      {
        "<tab>",
        function()
          return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
        end,
        expr = true, silent = true, mode = "i",
      },
      { "<tab>", function() require("luasnip").jump(1) end, mode = "s" },
      { "<s-tab>", function() require("luasnip").jump(-1) end, mode = { "i", "s" } },
    },
  },

  -----------------------------------------------------------------------------
  -- Autopairs ---------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    -- "echasnovski/mini.pairs",
    -- "windwp/nvim-autopairs",
    "jiangmiao/auto-pairs",
    -- event = "InsertEnter",
    -- config = true,
    -- opts = {
    --   disable_filetype = { "tex" },
    -- },
  },

  -----------------------------------------------------------------------------
  -- Completion ---------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      {
        "zbirenbaum/copilot.lua",
        dependencies = {
          "jonahgoldwastaken/copilot-status.nvim",
          opts = {
            icons = {
              idle = " ",
              error = " ",
              offline = "󰌸 ",
              warning = "⚠ ",
              loading = " ",
            },
          },
        },
        opts = {
          panel = { enabled = true },
          suggestion = { enabled = true },
          -- suggestion = {
          --   enabled = true,
          --   auto_trigger = true,
          --   keymap = {
          --     accept = "<M-CR>",
          --     next = "<M-RIGHT>",
          --     prev = "<M-LEFT>",
          --     dismiss = "<C-]>",
          --   },
          -- },
        },
      },
      { "zbirenbaum/copilot-cmp", config = true },
    },
    opts = function()
      local cmp = require "cmp"
      local luasnip = require "luasnip"
      local kind_icons = require("config.icons").kind

      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
      end

      return {
        -- completion = "menu,menuone,noinsert",
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = function(entry, vim_item)
            vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
            vim_item.menu = ({
              copilot = "[Copilot]",
              nvim_lsp = "[LSP]",
              nvim_lua = "[Nvim]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
            })[entry.source.name]
            return vim_item
          end,
        },
        sorting = {
          priority_weight = 2,
          comparators = {
            require("copilot_cmp.comparators").prioritize,

            -- Below is the default comparitor list and order for nvim-cmp
            cmp.config.compare.offset,
            -- cmp.config.compare.scopes, --this is commented in nvim-cmp too
            cmp.config.compare.exact,
            cmp.config.compare.score,
            cmp.config.compare.recently_used,
            cmp.config.compare.locality,
            cmp.config.compare.kind,
            cmp.config.compare.sort_text,
            cmp.config.compare.length,
            cmp.config.compare.order,
          },
        },
        sources = {
          { name = "copilot" },
          { name = "nvim_lsp" },
          { name = "nvim_lua" },
          { name = "luasnip" },
          { name = "path" },
          {
            name = "buffer",
            option = {
              keyword_length = 2,
              keyword_pattern = [[\d\@!\k\k*]],
            },
          },
        },
        mapping = {
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
          ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
          ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
          ["<C-y>"] = cmp.config.disable,
          ["<C-e>"] = cmp.mapping {
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
          },
          ["<CR>"] = cmp.mapping.confirm { select = false },
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        },
      }
    end,
  },

  -----------------------------------------------------------------------------
  -- Telescope ----------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
      defaults = {
        file_ignore_patterns = { "node_modules", ".DS_Store" },
      },
      pickers = {
        find_files = {
          hidden = true,
        },
      },
    },
    keys = function()
      local t = require "telescope.builtin"

      return {
        { "<C-p>", t.find_files, desc = "Telescope Find Files" },
        { "<leader>ff", t.find_files, desc = "Telescope Find Files" },
        { "<leader>fb", t.buffers, desc = "Telescope Find Buffers" },
        { "<leader>fw", t.live_grep, desc = "Telescope Find Words" },
        { "<leader>fh", t.help_tags, desc = "Telescope Find Help" },
        { "<leader>fc", t.commands, desc = "Telescope Find Commands" },
      }
    end,
  },

  -----------------------------------------------------------------------------
  -- Treesitter ---------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    dependencies = {
      "HiPhish/rainbow-delimiters.nvim",
      { "nvim-treesitter/nvim-treesitter-context", opts = {} },
      { "JoosepAlviste/nvim-ts-context-commentstring", opts = { enable_autocmd = false } },
      "numToStr/Comment.nvim",
    },
    keys = {
      { "<C-e>", vim.show_pos, desc = "Inspect syntax highlights" },
    },
    config = function()
      require("config.treesitter").setup()
      require("Comment").setup {
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      }
    end,
  },
}
