return {
  -- { "karb94/neoscroll.nvim", config = true },
  -----------------------------------------------------------------------------
  -- Lualine ------------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      return {
        options = {
          icons_enabled = true,
          component_separators = "", -- { left = "", right = "" },
          section_separators = "", -- { left = "", right = "" },
          always_divide_middle = true,
          globalstatus = true,
        },
        sections = {
          lualine_a = {},
          lualine_b = {
            "branch",
            "diff",
            "diagnostics",
            {
              function()
                return require("copilot_status").status_string()
              end,
              cond = function()
                return require("copilot_status").enabled()
              end,
            },
          },
          lualine_c = {
            { "filename", path = 1 },
            {
              function()
                local buf_ft = vim.bo.filetype
                local clients = vim.lsp.get_clients {
                  bufnr = 0,
                } -- Gets active LSP clients for the current buffer
                if next(clients) == nil then
                  return ""
                end

                local buf_client_names = {}

                for _, client in ipairs(clients) do
                  local filetypes = client.config.filetypes

                  if filetypes and vim.tbl_contains(filetypes, buf_ft) then
                    table.insert(buf_client_names, client.name)
                  end
                end

                return table.concat(buf_client_names, ", ")
              end,
              icon = " LSP:",
            },
          },
          lualine_x = {
            "encoding",
            "fileformat",
            "filetype",
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
        tabline = {},
        extensions = {
          "toggleterm",
          "neo-tree",
          "symbols-outline",
          "lazy",
        },
      }
    end,
    config = function(_, opts)
      require("lualine").setup(opts)

      if vim.env.TMUX then
        -- Tpipeline can export 'statusline' while Neovim keeps it hidden.
        vim.opt.laststatus = 0
        vim.opt.showmode = false

        local pane = vim.env.TMUX_PANE
        local last_style

        local function hex(color)
          return color and string.format("#%06x", color) or nil
        end

        local function publish_mode_colors()
          local suffix = require("lualine.highlight").get_mode_suffix()
          local hl = vim.api.nvim_get_hl(0, {
            name = "lualine_a" .. suffix,
            link = false,
          })
          local fg, bg = hex(hl.fg), hex(hl.bg)
          local style = string.format("%s:%s", fg or "", bg or "")

          if not fg or not bg or style == last_style then
            return
          end
          last_style = style

          vim.system {
            "tmux",
            "set-option",
            "-t",
            pane,
            "@nvim_mode_fg",
            fg,
            ";",
            "set-option",
            "-t",
            pane,
            "@nvim_mode_bg",
            bg,
            ";",
            "refresh-client",
            "-S",
          }
        end

        vim.api.nvim_create_autocmd({ "ModeChanged", "FocusGained", "ColorScheme" }, {
          group = vim.api.nvim_create_augroup("TmuxLualineModeColors", { clear = true }),
          desc = "Share Lualine mode colors with tmux",
          callback = function()
            vim.schedule(publish_mode_colors)
          end,
        })

        vim.schedule(publish_mode_colors)
      end
    end,
  },
  {
    "vimpostor/vim-tpipeline",
    event = "VeryLazy",
    dependencies = { "nvim-lualine/lualine.nvim" },
    init = function()
      -- The Nightfox tmux theme embeds the exported Lualine content.
      vim.g.tpipeline_autoembed = 0
      vim.g.tpipeline_split = 1
      vim.g.tpipeline_restore = 0
    end,
  },

  -----------------------------------------------------------------------------
  -- Bufferline ---------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons", "moll/vim-bbye" },
    keys = {
      { "<S-l>", "<CMD>BufferLineCycleNext<CR>", desc = "Go to next buffer" },
      { "<S-h>", "<CMD>BufferLineCyclePrev<CR>", desc = "Go to prev buffer" },
      { "<leader>c", "<CMD>:Bdelete<CR>", desc = "Close buffer" },
    },
    opts = {
      options = {
        close_command = "Bdelete! %d",
        max_name_length = 20,
        max_prefix_length = 15,
        tab_size = 22,
        diagnostics = "nvim_lsp",
        separator_style = { "▏", "▕" },
        show_close_icon = false,
        offsets = {
          {
            filetype = "neo-tree",
            text = " ----- File Explorer ----- ",
            highlight = "Directory",
            text_align = "left",
          },
        },
      },
    },
  },

  -----------------------------------------------------------------------------
  -- ToggleTerm ---------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "akinsho/toggleterm.nvim",
    event = "VeryLazy",
    opts = {
      open_mapping = [[<F12>]],
      direction = "horizontal",
      size = 24,
      shade_level = 5,
      float_opts = {
        border = "curved",
      },
    },
  },

  -----------------------------------------------------------------------------
  -- Neotree ------------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "nvim-neo-tree/neo-tree.nvim",
    cmd = "Neotree",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-tree/nvim-web-devicons",
        opts = {
          override_by_filename = {
            ["tsconfig.json"] = {
              icon = "󰛦",
            },
          },
          override_by_extension = {
            tex = { icon = "" },
            cls = { icon = "" },
            sty = { icon = "" },
          },
        },
      },
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<C-b>", "<CMD>Neotree toggle<CR>", desc = "Toggle NeoTree" },
      { "<C-c>", "<CMD>Neotree close<CR>", desc = "Close NeoTree" },
      { "<C-g>", "<CMD>Neotree focus<CR>", desc = "Focus NeoTree" },
      { "<leader>ft", "<CMD>Neotree float<CR>", desc = "Float NeoTree" },
    },
    deactivate = function()
      vim.cmd "Neotree close"
    end,
    init = function()
      vim.g.neo_tree_remove_legacy_commands = 1
      if vim.fn.argc() == 1 then
        local stat = vim.uv.fs_stat(vim.fn.argv(0))
        if stat and stat.type == "directory" then
          require "neo-tree"
        end
      end
    end,
    opts = {
      window = {
        width = 32,
      },
      filesystem = {
        follow_current_file = {
          enabled = true,
        },
        bind_to_cwd = false,
        filtered_items = {
          hide_dotfiles = false,
          hide_hidden = false,
          show_hidden_count = false,
          hide_gitignored = false,
        },
      },
      default_component_configs = {
        indent = {
          with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
          expander_collapsed = "",
          expander_expanded = "",
          expander_highlight = "NeoTreeExpander",
        },
      },
    },
  },

  -----------------------------------------------------------------------------
  -- Minimap ------------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "nvim-mini/mini.map",
    version = false,
    event = { "BufReadPost", "BufNewFile" },
    keys = {
      {
        "<leader>mc",
        function()
          require("mini.map").close()
        end,
        desc = "Close minimap",
      },
      {
        "<leader>mf",
        function()
          require("mini.map").toggle_focus()
        end,
        desc = "Focus minimap",
      },
      {
        "<leader>mo",
        function()
          require("mini.map").open()
        end,
        desc = "Open minimap",
      },
      {
        "<leader>mr",
        function()
          require("mini.map").refresh()
        end,
        desc = "Refresh minimap",
      },
      {
        "<leader>ms",
        function()
          require("mini.map").toggle_side()
        end,
        desc = "Toggle minimap side",
      },
      {
        "<leader>mt",
        function()
          require("mini.map").toggle()
        end,
        desc = "Toggle minimap",
      },
    },
    config = function()
      local map = require "mini.map"

      map.setup {
        integrations = {
          map.gen_integration.diagnostic {
            error = "DiagnosticFloatingError",
            warn = "DiagnosticFloatingWarn",
            info = "DiagnosticFloatingInfo",
            hint = "DiagnosticFloatingHint",
          },
          map.gen_integration.gitsigns(),
          map.gen_integration.builtin_search(),
        },
        symbols = {
          encode = map.gen_encode_symbols.dot "4x2",
          scroll_line = "▶",
          scroll_view = "┋",
        },
        window = {
          side = "right",
          width = 12,
          winblend = 0,
          show_integration_count = true,
        },
      }

      local function is_file_buffer(buf)
        return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
      end

      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("MiniMapAutoOpen", { clear = true }),
        desc = "Open mini.map for file buffers",
        callback = function(args)
          if is_file_buffer(args.buf) then
            map.open()
          end
        end,
      })

      if is_file_buffer(vim.api.nvim_get_current_buf()) then
        map.open()
      end
    end,
  },

  -----------------------------------------------------------------------------
  -- Which Key ----------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show { global = false }
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
  },
}
