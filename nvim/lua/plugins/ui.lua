vim.pack.add {
  "https://github.com/catgoose/nvim-colorizer.lua",
  "https://github.com/nvim-mini/mini.indentscope",
}

--------------------------------------------------------------------------------
------------------------------ Color previews ----------------------------------
--------------------------------------------------------------------------------
-- zsh prompt colors: %F{4}, %K{blue}, %F{208}, %F{#719cd6}, $fg[blue],
-- $fg_bold[red], $bg[green]. A numbered color is looked up, in order, in:
--   1. kitty's config (colorN lines, following includes), since kitty is what
--      really draws the prompt; this also covers extras like color16/17
--   2. the colorscheme's terminal palette (vim.g.terminal_color_0..15)
--   3. the standard xterm 256-color table
local zsh_color_names = {
  black = 0,
  red = 1,
  green = 2,
  yellow = 3,
  blue = 4,
  magenta = 5,
  cyan = 6,
  white = 7,
}

-- kitty's palette, { [n] = "rrggbb" }, read once on first use
local kitty_palette

local function read_kitty_palette()
  local palette, seen = {}, {}
  local dir = vim.env.KITTY_CONFIG_DIRECTORY or vim.fs.joinpath(vim.env.HOME, ".config", "kitty")
  local function read(path)
    path = vim.fs.normalize(path)
    if seen[path] or vim.fn.filereadable(path) == 0 then
      return
    end
    seen[path] = true
    -- Later lines win, like in kitty itself
    for line in io.lines(path) do
      local n, hex = line:match "^%s*color(%d+)%s+#(%x%x%x%x%x%x)%s*$"
      if n then
        palette[tonumber(n)] = hex:lower()
      end
      local include = line:match "^%s*include%s+(.-)%s*$"
      if include then
        read(include:sub(1, 1) == "/" and include or vim.fs.joinpath(dir, include))
      end
    end
  end
  read(vim.fs.joinpath(dir, "kitty.conf"))
  return palette
end

-- Color number (0-255) -> "rrggbb", or nil
local function terminal_color(n)
  if n > 255 then
    return nil
  end
  kitty_palette = kitty_palette or read_kitty_palette()
  if kitty_palette[n] then
    return kitty_palette[n]
  end
  local themed = n < 16 and vim.g["terminal_color_" .. n]
  if type(themed) == "string" and themed:match "^#%x%x%x%x%x%x$" then
    return themed:sub(2):lower()
  end
  return require("colorizer.parser.xterm").lookup_256(n)
end

local zsh_prompt_parser = {
  name = "zsh_prompt",
  prefixes = { "%F{", "%K{", "$fg[", "$fg_bold[", "$fg_no_bold[", "$bg[" },
  ---@param ctx colorizer.ParserContext
  parse = function(ctx)
    local rest = ctx.line:sub(ctx.col)
    -- %F{...} / %K{...}: a number, a color name or a #rrggbb hex value
    local value = rest:match "^%%[FK]{([^}]*)}"
    -- $fg[name] and friends: only color names
    if not value then
      value = rest:match "^%$[bf][g_a-z]*%[(%a+)%]"
    end
    if not value then
      return nil
    end

    local length = #rest:match "^[^}%]]*[}%]]"
    local hex = value:match "^#(%x%x%x%x%x%x)$"
    if hex then
      return length, hex:lower()
    end
    local n = tonumber(value) or zsh_color_names[value]
    local rgb = n and terminal_color(n)
    if rgb then
      return length, rgb
    end
  end,
}

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
      custom = { zsh_prompt_parser },
    },
  },
}

--------------------------------------------------------------------------------
------------------------------ Indent scope ------------------------------------
--------------------------------------------------------------------------------
local indentscope_group = vim.api.nvim_create_augroup("MiniIndentscopeExclude", { clear = true })

vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "TermOpen" }, {
  group = indentscope_group,
  desc = "Disable indent scope in utility buffers",
  callback = function(args)
    local excluded = { "help", "neo-tree", "minimap", "snacks_dashboard", "notify", "checkhealth", "qf" }
    if vim.bo[args.buf].buftype ~= "" or vim.tbl_contains(excluded, vim.bo[args.buf].filetype) then
      vim.b[args.buf].miniindentscope_disable = true
    end
  end,
})

-- The welcome screen sets up its buffer without firing FileType, so it gets
-- its own event
vim.api.nvim_create_autocmd("User", {
  group = indentscope_group,
  pattern = "SnacksDashboardOpened",
  desc = "Disable indent scope on the welcome screen",
  callback = function()
    vim.b.miniindentscope_disable = true
  end,
})

-- This file is loaded after the first screen (see init.lua): the welcome
-- screen may already be open
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.bo[buf].filetype == "snacks_dashboard" then
    vim.b[buf].miniindentscope_disable = true
  end
end

require("mini.indentscope").setup {
  symbol = "▍",
  options = { try_as_border = true },
}

--------------------------------------------------------------------------------
------------------------------ Trains ------------------------------------------
--------------------------------------------------------------------------------
-- The welcome screen's trams in a strip along the top while editing
-- (kitty only; lua/locktrains/strip.lua). :Trains shows or hides it,
-- :Trains 8 makes it 8 rows tall.
vim.api.nvim_create_user_command("Trains", function(opts)
  local rows = opts.args ~= "" and tonumber(opts.args) or nil
  if opts.args ~= "" and not (rows and rows >= 3) then
    vim.notify("Trains: give a number of rows (3 or more)", vim.log.levels.ERROR)
    return
  end
  require("locktrains.strip").toggle(rows and math.floor(rows))
end, { nargs = "?", desc = "Show or hide the trains along the top", force = true })
