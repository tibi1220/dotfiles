vim.pack.add {
  "https://github.com/catgoose/nvim-colorizer.lua",
  "https://github.com/nvim-mini/mini.indentscope",
  "https://github.com/goolord/alpha-nvim",
}

--------------------------------------------------------------------------------
------------------------------ Color previews ----------------------------------
--------------------------------------------------------------------------------
require("colorizer").setup {
  filetypes = { "*" },
  options = {
    parsers = {
      hex = {
        default = false,
        rgb = true,
        rrggbb = true,
        rrggbbaa = true,
      },
    },
  },
}

--------------------------------------------------------------------------------
------------------------------ Indent scope ------------------------------------
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "TermOpen" }, {
  group = vim.api.nvim_create_augroup("MiniIndentscopeExclude", { clear = true }),
  desc = "Disable indent scope in utility buffers",
  callback = function(args)
    local excluded = { "help", "oil", "neo-tree", "minimap", "alpha", "notify", "checkhealth", "qf" }
    if vim.bo[args.buf].buftype ~= "" or vim.tbl_contains(excluded, vim.bo[args.buf].filetype) then
      vim.b[args.buf].miniindentscope_disable = true
    end
  end,
})

require("mini.indentscope").setup {
  symbol = "▍",
  options = { try_as_border = true },
}

--------------------------------------------------------------------------------
------------------------------ Welcome screen ----------------------------------
--------------------------------------------------------------------------------
local dashboard = require "alpha.themes.dashboard"
local logo = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
]]

dashboard.section.header.val = vim.split(vim.trim(logo), "\n")
dashboard.section.buttons.val = {
  dashboard.button("f", "  Find file", "<Cmd>Telescope find_files<CR>"),
  dashboard.button("e", "  New file", "<Cmd>enew<CR><Cmd>startinsert<CR>"),
  dashboard.button("r", "  Recent files", "<Cmd>Telescope oldfiles<CR>"),
  dashboard.button("w", "  Find text", "<Cmd>Telescope live_grep<CR>"),
  dashboard.button("c", "  Config", "<Cmd>edit " .. vim.fn.fnameescape(vim.fn.stdpath "config" .. "/init.lua") .. "<CR>"),
  dashboard.button("s", "  Restore session", '<Cmd>lua require("persistence").load()<CR>'),
  dashboard.button("q", "  Quit", "<Cmd>qa<CR>"),
}

for _, button in ipairs(dashboard.section.buttons.val) do
  button.opts.hl = "AlphaButtons"
  button.opts.hl_shortcut = "AlphaShortcut"
end
dashboard.section.header.opts.hl = "AlphaHeader"
dashboard.section.buttons.opts.hl = "AlphaButtons"
dashboard.section.footer.opts.hl = "AlphaFooter"
dashboard.config.layout[1].val = 8

dashboard.section.footer.val = function()
  local count = 0
  for _, plugin in ipairs(vim.pack.get()) do
    if plugin.active then
      count = count + 1
    end
  end
  return string.format("⚡ Neovim · %d plugins", count)
end

local function dashboard_highlights()
  for name, target in pairs {
    AlphaHeader = "Type",
    AlphaButtons = "Normal",
    AlphaShortcut = "Keyword",
    AlphaFooter = "Comment",
  } do
    vim.api.nvim_set_hl(0, name, { link = target, default = true })
  end
end
dashboard_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("AlphaHighlights", { clear = true }),
  callback = dashboard_highlights,
})

require("alpha").setup(dashboard.config)
