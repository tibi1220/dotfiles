-- nvim --headless '+lua dofile("tests/smoke.lua")' to test the installed config.
local failures, checks = {}, 0
local function check(ok, message)
  checks = checks + 1
  if not ok then
    failures[#failures + 1] = message
  end
end
local function run()
  vim.o.lines = 60
  vim.o.columns = 160
  local errors = {}
  local notify = vim.notify
  vim.notify = function(message, level, opts)
    if level == vim.log.levels.ERROR then
      errors[#errors + 1] = tostring(message)
    end
    return notify(message, level, opts)
  end
  require("persistence").stop()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  vim.cmd.cd(dir)
  vim.fn.writefile({ "{}" }, dir .. "/package.json")
  local fixtures = {
    { "sample.lua", "lua", "lua", { "local x={a=1}", "return x" }, "lua_ls" },
    { "sample.c", "c", "c", { "int main(void) { return 0; }" }, "clangd" },
    { "sample.html", "html", "html", { "<html><body><div>Hello</div></body></html>" }, "emmet_ls" },
    { "sample.tsx", "typescriptreact", "tsx", { "const App = () => <div>Hello</div>;" } },
    { "sample.py", "python", "python", { "x=1" } },
    {
      "sample.tex",
      "tex",
      "latex",
      { "\\documentclass{article}", "\\begin{document}", "Hello", "\\end{document}" },
      "texlab",
    },
    { "sample.md", "markdown", "markdown", { "# Hello", "", "Some **text**." } },
    { "sample.mdx", "markdown", "markdown", { "# Hello", "", "<Component />" } },
  }
  for _, fixture in ipairs(fixtures) do
    local name, ft, lang, lines, server = unpack(fixture)
    vim.fn.writefile(lines, dir .. "/" .. name)
    vim.cmd.edit(dir .. "/" .. name)
    vim.wait(100)
    local buf = vim.api.nvim_get_current_buf()
    check(vim.bo.filetype == ft, name .. ": filetype")
    check(vim.treesitter.highlighter.active[buf] ~= nil, name .. ": highlighting")
    local parser = vim.treesitter.get_parser(buf, lang)
    check(parser and #parser:parse() > 0, name .. ": parser")
    if server then
      check(
        vim.wait(15000, function()
          local clients = vim.lsp.get_clients { bufnr = buf, name = server }
          return clients[1] and clients[1].initialized
        end, 100),
        name .. ": " .. server .. " attaches"
      )
      vim.wait(200)
      local client = vim.lsp.get_clients({ bufnr = buf, name = server })[1]
      if client and client:supports_method("textDocument/definition", buf) then
        check(vim.fn.maparg("gd", "n") ~= "", name .. ": definition mapping")
      end
    end
    if ft == "tex" then
      check(vim.b.vimtex ~= nil, "VimTeX initialized")
      check(not vim.bo.indentexpr:find "nvim%-treesitter", "TeX keeps VimTeX indentation")
      check(vim.fn.maparg("]]", "i") == "", "TeX ]] mapping removed")
      check(vim.fn.readfile("/tmp/vimtexserver.txt")[1] == vim.v.servername, "Skim inverse-search server")
    end
    if ft == "lua" or ft == "python" or ft == "html" or ft == "tex" or ft == "markdown" then
      local before = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
      require("plugins.lsp.format").format { force = true }
      local after = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
      if ft == "lua" or ft == "python" or ft == "html" then
        check(before ~= after, name .. ": external formatter edits buffer")
      end
      check(#require("conform").list_formatters(buf) > 0, name .. ": formatter available")
      vim.cmd.write()
    end
  end
  require("lazy").load {
    plugins = { "nvim-cmp", "telescope.nvim", "neo-tree.nvim", "toggleterm.nvim", "lualine.nvim", "bufferline.nvim" },
  }
  vim.wait(500)
  check(#require("luasnip").get_snippets "tex" > 0, "custom TeX snippets loaded")
  check(#require("luasnip").get_snippets "typescriptreact" > 0, "custom TSX snippets loaded")
  check(require "luasnip.util.jsregexp" ~= nil, "snippet regex engine")
  check(#require("cmp").get_config().sources == 6, "completion sources preserved")
  check(vim.fn.exists ":MarkdownPreview" == 2, "Markdown preview command")
  check(
    vim.fn.executable(vim.fn.stdpath "data" .. "/lazy/markdown-preview.nvim/app/bin/markdown-preview-macos-arm64") == 1,
    "Markdown preview executable"
  )
  check(vim.fn.maparg("<C-j>", "c", false, true).expr == 1, "command completion expression mapping")
  check(vim.fn.maparg("<leader>f", "n") ~= "", "manual format mapping")
  local format = require "plugins.lsp.format"
  format.toggle()
  check(not format.autoformat, "disable format on save")
  format.toggle()
  check(format.autoformat, "enable format on save")
  vim.cmd.edit(dir .. "/sample.lua")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x={a=1}", "return x" })
  format.toggle()
  vim.cmd.write()
  check(vim.fn.readfile(dir .. "/sample.lua")[1] == "local x={a=1}", "disabled save leaves formatting unchanged")
  format.toggle()
  vim.cmd.write()
  check(vim.fn.readfile(dir .. "/sample.lua")[1] ~= "local x={a=1}", "enabled save formats the file")
  vim.b.autoformat = false
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x={a=1}", "return x" })
  format.format { force = true }
  check(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] ~= "local x={a=1}", "manual formatting overrides buffer opt-out")
  vim.b.autoformat = nil
  vim.cmd.write()
  require("telescope.builtin").find_files { cwd = dir }
  vim.wait(200)
  check(vim.bo.filetype == "TelescopePrompt", "file picker opens")
  require("telescope.actions").close(vim.api.nvim_get_current_buf())
  vim.wait(200)
  vim.cmd("Neotree focus dir=" .. dir)
  vim.wait(200)
  check(vim.bo.filetype == "neo-tree", "file explorer opens")
  vim.cmd "Neotree close"
  require("toggleterm").toggle(1, 12, dir, "horizontal")
  vim.wait(200)
  check(vim.bo.buftype == "terminal", "terminal opens")
  require("toggleterm").toggle()
  -- vim.v.errmsg also retains errors intentionally suppressed by stock ftplugins.
  local messages = vim.api.nvim_exec2("messages", { output = true }).output
  check(not messages:find "Error", "surfaced Vim errors: " .. messages)
  check(#errors == 0, "runtime errors: " .. table.concat(errors, "\n"))
end
vim.defer_fn(function()
  local ok, err = xpcall(run, debug.traceback)
  if not ok then
    failures[#failures + 1] = err
  end
  vim.fn.writefile({ vim.json.encode { checks = checks, failures = failures } }, "/tmp/nvim-smoke-result.json")
  print(vim.inspect { checks = checks, failures = failures })
  vim.cmd(#failures == 0 and "qa!" or "cquit")
end, 100)
