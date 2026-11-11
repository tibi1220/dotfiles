vim.pack.add {
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/rafamadriz/friendly-snippets",
  "https://github.com/folke/lazydev.nvim",
  "https://github.com/stevearc/conform.nvim",
  {
    src = "https://github.com/saghen/blink.cmp",
    -- Release tags support automatic download of the Rust fuzzy matcher.
    version = vim.version.range "1",
  },
}

--------------------------------------------------------------------------------
------------------------------ Completion --------------------------------------
--------------------------------------------------------------------------------
local cmp = require "blink.cmp"

cmp.setup {
  keymap = {
    preset = "enter",
    ["<C-j>"] = { "select_next", "fallback" },
    ["<C-k>"] = { "select_prev", "fallback" },
    ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
    -- Esc with the menu open: undo the auto-inserted item and close the menu,
    -- staying in insert mode. Without the menu, Esc works as usual.
    ["<Esc>"] = { "cancel", "fallback" },
    ["<C-x><C-f>"] = {
      function(blink)
        return blink.show { providers = { "path" } }
      end,
    },
  },
  completion = {
    -- Nothing is selected until Tab/C-j; the selected item is then written
    -- into the buffer right away, so typing on simply continues after it.
    -- Enter accepts it fully (snippets, auto-imports), C-e undoes it.
    list = { selection = { preselect = false, auto_insert = true } },
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
  },
  sources = {
    default = { "lazydev", "lsp", "path", "snippets", "buffer" },
    providers = {
      path = {
        name = "Path",
        score_offset = 25,
        opts = {
          trailing_slash = true,
          label_trailing_slash = true,
          show_hidden_files_by_default = true,
          get_cwd = function(context)
            local filename = vim.api.nvim_buf_get_name(context.bufnr)
            if filename == "" or vim.bo[context.bufnr].buftype ~= "" then
              return vim.fn.getcwd()
            end
            return vim.fs.dirname(filename)
          end,
        },
      },
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        score_offset = 100,
      },
    },
  },
  signature = { enabled = true },
  fuzzy = { implementation = "prefer_rust_with_warning" },
}

-- LuaLS support for Neovim APIs and plugin types; independent of lazy.nvim.
require("lazydev").setup {}

--------------------------------------------------------------------------------
------------------------------ Language servers --------------------------------
--------------------------------------------------------------------------------
-- Install the server executables yourself and put them on Neovim's PATH.
-- Override a server's `cmd` below if it lives elsewhere.
vim.lsp.config("*", {
  capabilities = cmp.get_lsp_capabilities(),
})

local servers = {
  clangd = {
    capabilities = { offsetEncoding = { "utf-16" } },
  },
  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim", "tex", "jit", "bit", "bit32" } },
      },
    },
  },
  pyright = {
    -- Prefer an activated environment, then a virtualenv in the project root.
    before_init = function(_, config)
      local function python_in(venv)
        local executable = vim.fs.joinpath(venv, "bin", "python")
        if vim.fn.executable(executable) == 1 then
          return executable
        end
      end

      local python = vim.env.VIRTUAL_ENV and python_in(vim.env.VIRTUAL_ENV)
      if not python and config.root_dir then
        for _, name in ipairs { ".venv", "venv", "env" } do
          python = python_in(vim.fs.joinpath(config.root_dir, name))
          if python then
            break
          end
        end
      end

      if python then
        config.settings = config.settings or {}
        config.settings.python = config.settings.python or {}
        config.settings.python.pythonPath = python
      end
    end,
  },
  emmet_ls = {
    init_options = {
      html = { options = { ["output.selfClosingStyle"] = "xhtml" } },
      jsx = { options = { ["output.selfClosingStyle"] = "xhtml" } },
    },
  },
  texlab = {},
}

for name, config in pairs(servers) do
  vim.lsp.config(name, config)
end

--------------------------------------------------------------------------------
------------------------------ Diagnostics -------------------------------------
--------------------------------------------------------------------------------
vim.diagnostic.config {
  -- Show the message only for the line under the cursor.
  virtual_text = { current_line = true },
  severity_sort = true,
  float = { source = "if_many" },
}

--------------------------------------------------------------------------------
------------------------------ LSP shortcuts -----------------------------------
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    -- Keymaps from the previous (lazy.nvim) config. `method` skips a mapping
    -- when the server doesn't support it.
    local function map(mode, lhs, rhs, desc, method)
      if not method or client:supports_method(method, args.buf) then
        vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
      end
    end

    -- Jump to the next/previous diagnostic (optionally only of one severity)
    -- and show it in a float.
    local function diagnostic_goto(next, severity)
      severity = severity and vim.diagnostic.severity[severity] or nil
      return function()
        vim.diagnostic.jump {
          count = next and 1 or -1,
          severity = severity,
          on_jump = function(diagnostic, bufnr)
            if diagnostic then
              vim.diagnostic.open_float { bufnr = bufnr, scope = "cursor" }
            end
          end,
        }
      end
    end

    -- Several results open in a picker (snacks.picker); a single one is
    -- jumped to directly
    local picker = Snacks.picker
    map("n", "<leader>cd", vim.diagnostic.open_float, "Line Diagnostics")
    map("n", "<leader>cl", "<Cmd>checkhealth vim.lsp<CR>", "Lsp Info")
    map("n", "gd", picker.lsp_definitions, "Goto Definition", "textDocument/definition")
    map("n", "gr", picker.lsp_references, "References")
    map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
    map("n", "gI", picker.lsp_implementations, "Goto Implementation")
    map("n", "gy", picker.lsp_type_definitions, "Goto T[y]pe Definition")
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "gK", vim.lsp.buf.signature_help, "Signature Help", "textDocument/signatureHelp")
    map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature Help", "textDocument/signatureHelp")
    map("n", "]d", diagnostic_goto(true), "Next Diagnostic")
    map("n", "[d", diagnostic_goto(false), "Prev Diagnostic")
    map("n", "]e", diagnostic_goto(true, "ERROR"), "Next Error")
    map("n", "[e", diagnostic_goto(false, "ERROR"), "Prev Error")
    map("n", "]w", diagnostic_goto(true, "WARN"), "Next Warning")
    map("n", "[w", diagnostic_goto(false, "WARN"), "Prev Warning")
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action", "textDocument/codeAction")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename", "textDocument/rename")
    map("n", "<leader>cA", function()
      vim.lsp.buf.code_action {
        context = {
          only = { "source" },
          diagnostics = {},
        },
      }
    end, "Source Action", "textDocument/codeAction")
  end,
})

vim.lsp.enable(vim.tbl_keys(servers))

--------------------------------------------------------------------------------
------------------------------ Formatting --------------------------------------
--------------------------------------------------------------------------------
local conform = require "conform"

-- Format-on-save can be toggled for this Neovim session.
if vim.g.autoformat == nil then
  vim.g.autoformat = true
end

conform.setup {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_format" },

    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    html = { "prettier" },
    css = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },

    tex = { "latexindent" },
    plaintex = { "latexindent" },
  },
  default_format_opts = {
    lsp_format = "fallback",
  },
  format_on_save = function()
    if vim.g.autoformat == false then
      return
    end
    return { timeout_ms = 3000 }
  end,
}

vim.keymap.set({ "n", "x" }, "<leader>cf", function()
  conform.format { async = true }
end, { desc = "Format document or selection" })

vim.keymap.set("n", "<leader>tf", function()
  vim.g.autoformat = not vim.g.autoformat
  vim.notify("Format on save " .. (vim.g.autoformat and "enabled" or "disabled"))
end, { desc = "Toggle format on save" })
