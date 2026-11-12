-- :Trains — LockTrains while editing: the town, its overhead wires, the
-- tram stop and the trams, in a strip across the first rows of the screen,
-- above everything else. No sky: the editor's background shows above the
-- roofs.
--
-- How the rows are kept for it:
--   * The strip is a split window across the whole width, at the very top,
--     with an empty buffer; kitty.lua draws the "strip" scene in it. It
--     takes its rows from the windows below instead of covering any text.
--   * Neovim always draws its tab line (bufferline) on the screen's first
--     row, above every window. So while the strip is shown, that is turned
--     off and the tab line is drawn in a one-row floating window right
--     under the strip instead (on the row between the strip and the windows
--     below, which would be an empty statusline or a separator). Mouse
--     clicks on it don't work there.
--   * mini.map's minimap starts below the tab line: it asks M.top_rows()
--     where to start (see the minimap in plugins/editor.lua), and is told
--     to place itself again when the strip changes.
--
--   :Trains      show or hide it
--   :Trains 8    show it 8 rows tall (or make it 8 rows tall)
--   q            in the strip: hide it

local M = {}

-- Rows, unless :Trains is given a number
M.ROWS = 7

local win, buf, group, timer
-- The strip's height, in rows
local height
-- The tab line's floating window and buffer, the last thing drawn in it,
-- and 'showtabline' from before
local bar = {}
local saved_showtabline

local ns = vim.api.nvim_create_namespace "locktrains-strip"

local function is_open()
  return win ~= nil and vim.api.nvim_win_is_valid(win)
end

local function valid(w)
  return w ~= nil and vim.api.nvim_win_is_valid(w)
end

--------------------------------------------------------------------------------
-- The tab line, under the strip
--------------------------------------------------------------------------------

-- Whether the tab line was shown before the strip took its place
local function had_tabline()
  return saved_showtabline == 2 or (saved_showtabline == 1 and #vim.api.nvim_list_tabpages() > 1)
end

-- The tab line's place: the row under the strip, the whole width
local function bar_config()
  return {
    relative = "editor",
    row = vim.api.nvim_win_get_height(win),
    col = 0,
    width = vim.o.columns,
    height = 1,
  }
end

-- Draw the tab line ('tabline', e.g. bufferline's) into its window, if it
-- changed
local function draw_bar()
  if not is_open() or not valid(bar.win) then
    return
  end
  local text, highlights = "", {}
  if vim.o.tabline ~= "" then
    -- bufferline makes room above a file tree (its "offsets") by looking
    -- at the first window of the layout, which is now the strip: while
    -- it's drawn, the layout is given without the strip
    local winlayout = vim.fn.winlayout
    vim.fn.winlayout = function(...)
      local layout = winlayout(...)
      if layout[1] == "col" and layout[2][1][1] == "leaf" and layout[2][1][2] == win then
        local rest = vim.list_slice(layout[2], 2)
        return #rest == 1 and rest[1] or { "col", rest }
      end
      return layout
    end
    local ok, result = pcall(
      vim.api.nvim_eval_statusline,
      vim.o.tabline,
      { use_tabline = true, highlights = true, maxwidth = vim.o.columns }
    )
    vim.fn.winlayout = winlayout
    if ok then
      text, highlights = result.str, result.highlights
    end
  end
  -- bufferline turns the real tab line back on whenever it's drawn
  vim.o.showtabline = 0

  local key = { text }
  for _, hl in ipairs(highlights) do
    key[#key + 1] = hl.start .. hl.group
  end
  key = table.concat(key, "\0")
  if key == bar.last then
    return
  end
  bar.last = key
  vim.bo[bar.buf].modifiable = true
  vim.api.nvim_buf_set_lines(bar.buf, 0, -1, false, { text })
  vim.bo[bar.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(bar.buf, ns, 0, -1)
  for i, hl in ipairs(highlights) do
    local finish = highlights[i + 1] and highlights[i + 1].start or #text
    if finish > hl.start then
      vim.api.nvim_buf_set_extmark(bar.buf, ns, 0, hl.start, { end_col = finish, hl_group = hl.group })
    end
  end
end

local function open_bar()
  bar.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[bar.buf].bufhidden = "wipe"
  local config = bar_config()
  config.style = "minimal"
  config.focusable = false
  config.noautocmd = true
  config.border = "none"
  config.zindex = 20
  bar.win = vim.api.nvim_open_win(bar.buf, false, config)
  -- The rest of the row in the tab line's background
  vim.wo[bar.win].winhighlight = "Normal:TabLineFill"
  bar.last = nil
  draw_bar()
end

-- Keep the tab line under the strip, as wide as the screen
local function place_bar()
  if is_open() and valid(bar.win) then
    vim.api.nvim_win_set_config(bar.win, bar_config())
    bar.last = nil
    draw_bar()
  end
end

--------------------------------------------------------------------------------
-- Making room
--------------------------------------------------------------------------------

-- The screen rows kept for the strip and the tab line under it (0 while
-- it's hidden): where floating windows along the side should start
function M.top_rows()
  if not is_open() then
    return 0
  end
  return vim.api.nvim_win_get_height(win) + 1
end

-- Let the minimap place itself again (below the strip, or back at the top)
local function place_minimap()
  if _G.MiniMap then
    pcall(MiniMap.refresh, {}, { integrations = false, lines = false, scrollbar = false })
  end
end

-- Keep the strip at the top across the whole width. A window opened with
-- :topleft vsplit or :botright vsplit (Neo-tree, ...) is as tall as the
-- screen and pushes the strip aside: move the strip back above everything
-- (:wincmd K), which puts the new window below it.
local function keep_on_top()
  local layout = vim.fn.winlayout()
  local on_top = layout[1] == "col" and layout[2][1][1] == "leaf" and layout[2][1][2] == win
  if not on_top and layout[1] ~= "leaf" then
    vim.api.nvim_win_call(win, function()
      vim.cmd "wincmd K"
    end)
  end
  if vim.api.nvim_win_get_height(win) ~= height then
    vim.api.nvim_win_set_height(win, height)
  end
end

-- Draw the scene to fit the window (again: after a resize it is laid out
-- anew, otherwise left as it is), and keep everything else out of its rows
local function fit()
  if not is_open() then
    M.close()
    return
  end
  keep_on_top()
  place_minimap()
  place_bar()
  if not require("locktrains.kitty").show("strip", win, buf) then
    M.close()
    vim.notify("Trains: can't get the terminal's cell size", vim.log.levels.WARN)
  end
end

--------------------------------------------------------------------------------
-- Showing and hiding
--------------------------------------------------------------------------------

function M.close()
  if group then
    pcall(vim.api.nvim_del_augroup_by_id, group)
    group = nil
  end
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
  require("locktrains.kitty").hide "strip"
  if valid(bar.win) then
    vim.api.nvim_win_close(bar.win, true)
  end
  bar = {}
  if is_open() then
    -- Fails if it's the last window; Neovim is quitting then anyway
    pcall(vim.api.nvim_win_close, win, true)
  end
  win, buf = nil, nil
  if saved_showtabline then
    vim.o.showtabline = saved_showtabline
    saved_showtabline = nil
  end
  place_minimap()
end

function M.open(rows)
  if not require("locktrains.kitty").available() then
    vim.notify("Trains need kitty, on this machine (not over SSH)", vim.log.levels.WARN)
    return
  end
  rows = rows or M.ROWS
  height = rows
  if is_open() then
    fit()
    return
  end

  -- The tab line goes under the strip (see the top)
  saved_showtabline = vim.o.showtabline
  vim.o.showtabline = 0

  buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "locktrains"
  vim.bo[buf].modifiable = false
  -- At the very top, across all windows (win = -1), not focused
  win = vim.api.nvim_open_win(buf, false, { split = "above", win = -1, height = rows, style = "minimal" })
  local wo = vim.wo[win][0]
  wo.winfixheight = true -- other windows opening or closing don't resize it
  wo.winfixbuf = true -- no file can be opened in it
  wo.fillchars = "eob: " -- no "~" on its empty lines
  wo.statuscolumn = ""
  wo.winbar = ""
  -- With laststatus=0 (in tmux), Neovim still puts a statusline under a
  -- window with another below it: keep that row empty (the tab line
  -- covers it, if there is one)
  wo.statusline = " "
  wo.winhighlight = "StatusLine:Normal,StatusLineNC:Normal"
  vim.keymap.set("n", "q", M.close, { buffer = buf, nowait = true, desc = "Hide the trains" })

  if had_tabline() then
    open_bar()
  end

  group = vim.api.nvim_create_augroup("LockTrainsStrip", { clear = true })
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized", "WinNew" }, {
    group = group,
    desc = "Fit the trains to the strip, keep others out of its rows",
    callback = function()
      vim.schedule(fit)
    end,
  })
  -- The tab line drawn again when what it shows may have changed (and
  -- every half second, for anything else)
  vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufAdd",
    "BufDelete",
    "BufWipeout",
    "BufModifiedSet",
    "BufWritePost",
    "WinEnter",
    "TabEnter",
    "DiagnosticChanged",
    "DirChanged",
  }, {
    group = group,
    desc = "Draw the tab line under the trains",
    callback = function()
      vim.schedule(draw_bar)
    end,
  })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      bar.last = nil
      vim.schedule(draw_bar)
    end,
  })
  timer = vim.uv.new_timer()
  timer:start(500, 500, vim.schedule_wrap(draw_bar))
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = tostring(win),
    desc = "Stop the trains with their window",
    callback = function()
      vim.schedule(M.close)
    end,
  })
  -- :q in the last window with a file: close the strip first, so Neovim
  -- quits instead of leaving the strip on its own
  vim.api.nvim_create_autocmd("QuitPre", {
    group = group,
    desc = "Close the trains with the last window",
    callback = function()
      local current = vim.api.nvim_get_current_win()
      for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if
          w ~= current
          and w ~= win
          and vim.api.nvim_win_get_config(w).relative == ""
          and vim.bo[vim.api.nvim_win_get_buf(w)].buftype == ""
        then
          return
        end
      end
      M.close()
    end,
  })
  -- Not saved in sessions (it would come back as an empty window)
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "PersistenceSavePre",
    desc = "Close the trains before saving the session",
    callback = M.close,
  })

  fit()
end

-- :Trains [rows]
function M.toggle(rows)
  if is_open() and not rows then
    M.close()
  else
    M.open(rows)
  end
end

return M
