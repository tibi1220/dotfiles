vim.pack.add { "https://github.com/lewis6991/gitsigns.nvim" }

local gitsigns = require "gitsigns"

gitsigns.setup {
  numhl = true,
  on_attach = function(bufnr)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
    end

    map("<leader>gd", gitsigns.diffthis, "Git diff")
    map("<leader>gb", gitsigns.blame_line, "Show Git blame for current line")
    map("<leader>gB", gitsigns.toggle_current_line_blame, "Toggle inline Git blame")
  end,
}

-- lazygit (<leader>gg, :Lazygit) is snacks.lazygit: see snacks.lua.
