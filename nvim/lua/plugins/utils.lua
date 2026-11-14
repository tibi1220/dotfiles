vim.pack.add {
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/nvim-mini/mini.pairs",
  "https://github.com/folke/persistence.nvim",
}

--------------------------------------------------------------------------------
------------------------------ Icons -------------------------------------------
--------------------------------------------------------------------------------
local devicons = require "nvim-web-devicons"
devicons.setup {}

--------------------------------------------------------------------------------
------------------------------ Icons -------------------------------------------
--------------------------------------------------------------------------------
require("mini.pairs").setup {}

--------------------------------------------------------------------------------
------------------------------ Sessions ----------------------------------------
--------------------------------------------------------------------------------
local persistence = require "persistence"
persistence.setup { branch = false }

local map = vim.keymap.set

-- stylua: ignore start

map("n", "<leader>qs", persistence.load, { desc = "Restore session" })
map("n", "<leader>qS", persistence.select, { desc = "Select session" })
map("n", "<leader>ql", function() persistence.load { last = true } end, { desc = "Restore last session" })
map("n", "<leader>qd", persistence.stop, { desc = "Don't save current session" })

-- stylua: ignore end
