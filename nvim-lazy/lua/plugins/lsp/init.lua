return {
  -----------------------------------------------------------------------------
  -- Nvim LSPconfig -----------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      require("utils").on_attach(function(client, buffer)
        require("plugins.lsp.keymaps").on_attach(client, buffer)
      end)

      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })
      local servers = require "plugins.lsp.servers"
      for server, opts in pairs(servers) do
        vim.lsp.config(server, opts)
      end
      -- Also enable servers installed manually in Mason (e.g. texlab).
      require("mason-lspconfig").setup {
        ensure_installed = vim.tbl_keys(servers),
        -- StyLua is used by Conform as a formatter, not as an LSP server.
        automatic_enable = { exclude = { "stylua" } },
      }
    end,
  },

  -----------------------------------------------------------------------------
  -- LSP Signature ------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "ray-x/lsp_signature.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "neovim/nvim-lspconfig" },
    opts = {
      bind = true,
      handler_opts = {
        border = "rounded",
      },
      max_width = 80,
      max_height = 100,
    },
  },

  -----------------------------------------------------------------------------
  -- Mason --------------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    opts = {
      ensure_installed = {
        "stylua",
        "prettier",
        "autopep8",
      },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require "mason-registry"
      local function ensure_installed()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end
      if mr.refresh then
        mr.refresh(ensure_installed)
      else
        ensure_installed()
      end
    end,
  },

  -----------------------------------------------------------------------------
  -- Formatting ---------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = "ConformInfo",
    dependencies = { "mason-org/mason.nvim" },
    keys = {
      {
        "<leader>f",
        function()
          require("plugins.lsp.format").format { force = true }
        end,
        mode = { "n", "v" },
        desc = "Format document or selection",
      },
    },
    opts = {
      default_format_opts = { lsp_format = "fallback", timeout_ms = 3000 },
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "autopep8" },
        tex = { "latexindent" },
        plaintex = { "latexindent" },
        bib = { "latexindent" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        svelte = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        handlebars = { "prettier" },
      },
      formatters = {
        latexindent = {
          prepend_args = function(_, ctx)
            local file = vim.api.nvim_buf_get_name(ctx.buf)
            local dir = vim.fs.dirname(file)
            local root = vim.b[ctx.buf].vimtex and vim.b[ctx.buf].vimtex.root or dir
            local yaml = root .. "/.latexindent.yaml"
            return { "-l=" .. yaml, "-c=" .. dir }
          end,
        },
      },
      format_on_save = function(buf)
        if require("plugins.lsp.format").autoformat and vim.b[buf].autoformat ~= false then
          return { lsp_format = "fallback", timeout_ms = 3000 }
        end
      end,
    },
  },

  -----------------------------------------------------------------------------
  -- Navic --------------------------------------------------------------------
  -----------------------------------------------------------------------------
  {
    "SmiteshP/nvim-navic",
    enabled = false,
    lazy = true,
    init = function()
      vim.g.navic_silence = true
      require("utils").on_attach(function(client, buffer)
        if client.server_capabilities.documentSymbolProvider then
          require("nvim-navic").attach(client, buffer)
        end
      end)
    end,
    opts = function()
      return {
        separator = "  ",
        depth_limit = 3,
        -- icons = require("config.icons").kind,
      }
    end,
  },
}
