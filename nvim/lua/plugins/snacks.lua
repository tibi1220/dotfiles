vim.pack.add {
  { src = "https://github.com/folke/snacks.nvim", version = vim.version.range "2" },
}

-- snacks.nvim is a collection of small modules; every module's settings go in
-- this one setup call. Only the image viewer is enabled for now.
--
-- Image viewer: opening an image (png, jpg, gif, webp, pdf, ...) shows it in
-- the buffer, and images / LaTeX math in Markdown are rendered inline.
-- Needs a terminal with the kitty graphics protocol (kitty, Ghostty, WezTerm;
-- through tmux with `allow-passthrough on`) and ImageMagick. Ghostscript is
-- used for PDFs, pdflatex/tectonic for math. Check with :checkhealth snacks.
require("snacks").setup {
  image = { enabled = true },
}
