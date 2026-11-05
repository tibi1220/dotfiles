-- Preserve the old MDX-as-Markdown behavior.
vim.filetype.add { extension = { mdx = "markdown" } }

-- Downloads the preview server binary. Failures (e.g. offline) only warn, so
-- the rest of the config still loads; the install is retried on next start.
local function install_preview(path)
  local ok, err = pcall(function()
    local package = vim.json.decode(table.concat(vim.fn.readfile(vim.fs.joinpath(path, "package.json")), "\n"))
    local result = vim.system({ "sh", "install.sh", "v" .. package.version }, {
      cwd = vim.fs.joinpath(path, "app"),
      text = true,
    }):wait()
    if result.code ~= 0 then
      error(result.stderr ~= "" and result.stderr or result.stdout, 0)
    end
  end)
  if not ok then
    vim.notify("Markdown Preview installation failed:\n" .. tostring(err), vim.log.levels.WARN)
  end
end

vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("MarkdownPreviewInstall", { clear = true }),
  desc = "Install Markdown Preview's browser server",
  callback = function(args)
    local event = args.data
    if event.spec.name == "markdown-preview.nvim" and event.kind ~= "delete" then
      install_preview(event.path)
    end
  end,
})

vim.pack.add { "https://github.com/iamcco/markdown-preview.nvim" }

-- Restore the preview binary if package cleanup removed generated files.
local preview = vim.pack.get({ "markdown-preview.nvim" })[1]
local platform = vim.fn["mkdp#util#get_platform"]()
local binary = "markdown-preview-" .. platform .. (platform == "win" and ".exe" or "")
if vim.fn.executable(vim.fs.joinpath(preview.path, "app", "bin", binary)) ~= 1 then
  install_preview(preview.path)
end
