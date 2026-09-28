return {
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPost",
    -- stylua: ignore
    keys = {
      { "<leader>dd", function() require("gitsigns").diffthis() end, desc = "Git diff" },
    },
    opts = {
      numhl = true,
      -- signs = {
      --   add = {
      --     hl = "GitSignsAdd",
      --     text = "▎", -- ▎
      --     numhl = "GitSignsAddNr",
      --     linehl = "GitSignsAddLn",
      --   },
      --   change = {
      --     hl = "GitSignsChange",
      --     text = "▎", -- ▎
      --     numhl = "GitSignsChangeNr",
      --     linehl = "GitSignsChangeLn",
      --   },
      --   delete = {
      --     hl = "GitSignsDelete",
      --     text = "_", -- 契
      --     numhl = "GitSignsDeleteNr",
      --     linehl = "GitSignsDeleteLn",
      --   },
      --   topdelete = {
      --     hl = "GitSignsDelete",
      --     text = "‾", -- 契
      --     numhl = "GitSignsDeleteNr",
      --     linehl = "GitSignsDeleteLn",
      --   },
      --   changedelete = {
      --     hl = "GitSignsChange",
      --     text = "▎", -- ▎
      --     numhl = "GitSignsChangeNr",
      --     linehl = "GitSignsChangeLn",
      --   },
      --   untracked = {
      --     hl = "KeyWord",
      --     text = "▎", -- ▎
      --     numhl = "KeyWord",
      --     linehl = "GitSignsDeleteLn",
      --   },
      -- },
    },
  },
  {
    "f-person/git-blame.nvim",
  },
  -- {
  --   "kdheepak/lazygit.nvim",
  --   dependencies = "nvim-lua/plenary.nvim",
  --   -- stylua: ignore
  --   keys = {
  --     { "<leader>lg", "<CMD>LazyGit<CR>", "Lazygit" },
  --   },
  -- },
  -- {
  --   "sindrets/diffview.nvim",
  --   keys = {
  --     -- stylua: ignore
  --     { "<leader>gg", "<CMD>DiffviewOpen<CR>", "Lazygit" },
  --   },
  -- },
}
