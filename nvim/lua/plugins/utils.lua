vim.pack.add {
  "https://github.com/nvim-mini/mini.icons",
  "https://github.com/nvim-mini/mini.pairs",
  "https://github.com/folke/persistence.nvim",
}

local icons = require "mini.icons"

icons.setup {
  file = {
    ["tsconfig.json"] = { glyph = "󰛦" },
  },
  extension = {
    tex = { glyph = "" },
    cls = { glyph = "" },
    sty = { glyph = "" },
  },
}

-- Serve mini.icons to plugins that expect nvim-web-devicons
-- (lualine, neo-tree, telescope, alpha, ...).
icons.mock_nvim_web_devicons()

require("mini.pairs").setup {}

--------------------------------------------------------------------------------
------------------------------ Sessions ----------------------------------------
--------------------------------------------------------------------------------
local persistence = require "persistence"
persistence.setup { branch = false }

local map = vim.keymap.set
map("n", "<leader>qs", persistence.load, { desc = "Restore session" })
map("n", "<leader>qS", persistence.select, { desc = "Select session" })
map("n", "<leader>ql", function()
  persistence.load { last = true }
end, { desc = "Restore last session" })
map("n", "<leader>qd", persistence.stop, { desc = "Don't save current session" })
