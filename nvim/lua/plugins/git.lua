vim.pack.add { "https://github.com/lewis6991/gitsigns.nvim" }

local gitsigns = require "gitsigns"

gitsigns.setup {
  numhl = true,
  on_attach = function(bufnr)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
    end

    map("<leader>dd", gitsigns.diffthis, "Git diff")
    map("<leader>gb", gitsigns.blame_line, "Show Git blame for current line")
    map("<leader>gB", gitsigns.toggle_current_line_blame, "Toggle inline Git blame")
  end,
}

-- Reuse one LazyGit process while showing and hiding its floating terminal.
local lazygit
vim.api.nvim_create_user_command("Lazygit", function()
  if vim.fn.executable "lazygit" ~= 1 then
    vim.notify("LazyGit is not installed or is missing from PATH", vim.log.levels.ERROR)
    return
  end

  if not lazygit then
    lazygit = require("toggleterm.terminal").Terminal:new {
      cmd = "lazygit",
      direction = "float",
      hidden = true,
      float_opts = { border = "rounded" },
    }
  end
  lazygit:toggle()
end, { desc = "Toggle LazyGit in a floating terminal", force = true })
