return {
  clangd = {
    capabilities = {
      offsetEncoding = { "utf-16" },
    },
  },
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = {
          globals = { "vim", "tex", "jit", "bit", "bit32" },
        },
        workspace = {
          library = {
            vim.env.VIMRUNTIME .. "/lua",
            vim.fn.stdpath "config" .. "/lua",
          },
        },
      },
    },
  },
  pyright = {
    -- Point pyright at the project's virtualenv so imports from installed
    -- packages resolve. Priority: an activated $VIRTUAL_ENV, then a
    -- .venv / venv / env directory in the project root.
    before_init = function(_, config)
      local function python_in(venv)
        local py = venv .. "/bin/python"
        if vim.fn.executable(py) == 1 then
          return py
        end
      end

      local python
      if vim.env.VIRTUAL_ENV then
        python = python_in(vim.env.VIRTUAL_ENV)
      end
      if not python and config.root_dir then
        for _, name in ipairs { ".venv", "venv", "env" } do
          python = python_in(config.root_dir .. "/" .. name)
          if python then
            break
          end
        end
      end

      if python then
        -- Mutate in place: the client already holds a reference to this table.
        config.settings = config.settings or {}
        config.settings.python = config.settings.python or {}
        config.settings.python.pythonPath = python
      end
    end,
  },
  emmet_ls = {
    init_options = {
      html = {
        options = {
          ["output.selfClosingStyle"] = "xhtml",
          -- ["jsx.enabled"] = true,
        },
      },
      jsx = {
        options = {
          ["output.selfClosingStyle"] = "xhtml",
        },
      },
    },
  },
}
