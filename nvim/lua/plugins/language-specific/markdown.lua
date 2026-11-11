-- Preserve the old MDX-as-Markdown behavior.
vim.filetype.add { extension = { mdx = "markdown" } }

-- Live preview in the browser: Markdown (with KaTeX math), HTML, AsciiDoc and
-- SVG. Pure Lua, so there is nothing to build or download after installing.
--   :LivePreview start   open the current file in the browser
--   :LivePreview close   stop the preview server
--   :LivePreview pick    choose a file to preview (with snacks.picker)
vim.pack.add { "https://github.com/brianhuster/live-preview.nvim" }

require("livepreview.config").set {
  picker = "snacks.picker",
  -- Scroll the browser along with the editor
  sync_scroll = true,
}

-- The old markdown-preview.nvim command names, kept for muscle memory
vim.api.nvim_create_user_command("MarkdownPreview", "LivePreview start", {
  desc = "Preview the current file in the browser",
})
vim.api.nvim_create_user_command("MarkdownPreviewStop", "LivePreview close", {
  desc = "Stop the browser preview",
})
