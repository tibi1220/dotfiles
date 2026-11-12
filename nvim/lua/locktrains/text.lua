-- LockTrains as text: the scene drawn with "▀" characters, each cell two
-- art pixels (the top one's color on the bottom one's), using the small art
-- sets (lua/locktrains/art/w120, w160, w200). Used where kitty's graphics
-- can't be (another terminal, SSH); see init.lua.

local scene = require "locktrains.scene"

local M = {}

-- Art sets by width, in art pixels (= terminal columns)
local SETS = { 120, 160, 200 }
-- Frames a second
local FPS = 15
-- Rows of sky kept above the town at least, in art pixels
local MIN_SKY = 4

local ns = vim.api.nvim_create_namespace "locktrains"
local state -- the running scene, or nil

--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------

-- Highlight groups for "▀" in each (top, bottom) color pair, made as needed
local hl_cache = {}

local function hl_for(top, bottom)
  local key = top * 16777216 + bottom
  local name = hl_cache[key]
  if not name then
    name = string.format("LockTrains%06x%06x", top, bottom)
    vim.api.nvim_set_hl(0, name, { fg = top, bg = bottom })
    hl_cache[key] = name
  end
  return name
end

-- :colorscheme clears all highlight groups, so make them again afterwards
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("LockTrainsColors", { clear = true }),
  callback = function()
    hl_cache = {}
  end,
})

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

-- Draw a sprite into the frame at art position (x, y). Pixels outside the
-- visible part (the crop) are skipped.
local function blit(s, art, key, x, y)
  local sprite = art.sprites[key]
  if not sprite or sprite.w == 0 then
    return
  end
  local palette, fb, w, h = art.palette, s.fb, s.w, s.h
  local left = x + sprite.x - s.left
  local top = y + sprite.y - s.top
  for row = 1, #sprite.rows do
    local fy = top + row - 1
    if fy >= 0 and fy < h then
      local runs, fx = sprite.rows[row], left
      local base = fy * w + 1
      for i = 1, #runs, 2 do
        local count, color = runs[i], runs[i + 1]
        if color ~= 0 then
          local c = palette[color]
          for dx = 0, count - 1 do
            local px = fx + dx
            if px >= 0 and px < w then
              fb[base + px] = c
            end
          end
        end
        fx = fx + count
      end
    end
  end
end

-- One frame of the scene at `t` seconds, as a list of rows of virtual text
local function frame(s, t)
  local art, fb, w, h = s.art, s.fb, s.w, s.h

  -- Sky
  for y = 0, h - 1 do
    local c, base = s.sky[y + s.top], y * w
    for x = 1, w do
      fb[base + x] = c
    end
  end

  -- Stars, each group brightening and dimming in its own phase, in 4 steps
  local signature = {}
  for _, group in ipairs(art.stars.groups) do
    local level = math.floor((0.5 + 0.5 * math.sin(t * art.stars.speed + group.phase)) * 3 + 0.5)
    signature[#signature + 1] = level
    if level > 0 then
      -- Each star pixel faded towards the sky behind it
      local sprite = art.sprites[group.sprite]
      local left, top = group.x + sprite.x - s.left, group.y + sprite.y - s.top
      for row = 1, #sprite.rows do
        local fy, runs, fx = top + row - 1, sprite.rows[row], left
        for i = 1, #runs, 2 do
          local count, color = runs[i], runs[i + 1]
          if color ~= 0 and fy >= 0 and fy < h then
            for dx = 0, count - 1 do
              local px = fx + dx
              if px >= 0 and px < w then
                local at = fy * w + 1 + px
                fb[at] = scene.mix(s.sky[fy + s.top], art.palette[color], level / 3)
              end
            end
          end
          fx = fx + count
        end
      end
    end
  end

  -- Moon, today's phase, kept fully in view
  blit(s, art, s.moon.sprite, s.moon.x, s.moon.y)

  -- Town, its lit windows
  blit(s, art, art.land.sprite, art.land.x, art.land.y)
  for _, wnd in ipairs(art.windows) do
    blit(s, art, wnd.sprite, wnd.x, wnd.y)
  end

  -- Train and doors
  local name, along, door = scene.train_at(art, t)
  local train = art.trains[name]
  if along then
    local x, y = scene.train_position(art, name, along)
    blit(s, art, train.sprite, x, y)
    if door > 0 then
      blit(s, art, train.doors[door], x + art.doors.x, y + art.doors.y)
    end
    signature[#signature + 1] = name .. x .. ":" .. door
  end

  -- Platform, in front of the train
  blit(s, art, art.platform.sprite, art.platform.x, art.platform.y)

  -- Nothing moved since the last frame: no need to redraw
  local key = table.concat(signature, ",")
  if key == s.last then
    return nil
  end
  s.last = key

  -- Two pixel rows to a line of "▀", one chunk per run of equal colors
  local lines = {}
  for row = 0, s.rows - 1 do
    local chunks, top_base, bottom_base = {}, (2 * row) * w, (2 * row + 1) * w
    local run_top, run_bottom, count = nil, nil, 0
    for x = 1, w do
      local top, bottom = fb[top_base + x], fb[bottom_base + x]
      if top == run_top and bottom == run_bottom then
        count = count + 1
      else
        if count > 0 then
          chunks[#chunks + 1] = { string.rep("▀", count), hl_for(run_top, run_bottom) }
        end
        run_top, run_bottom, count = top, bottom, 1
      end
    end
    chunks[#chunks + 1] = { string.rep("▀", count), hl_for(run_top, run_bottom) }
    lines[row + 1] = chunks
  end
  return lines
end

--------------------------------------------------------------------------------
-- The window
--------------------------------------------------------------------------------

-- Pick the art and its crop for a window: the narrowest set at least as wide
-- (cropped at both sides), the sky trimmed from the top to fit under the
-- welcome screen's text. Returns nil if even the town doesn't fit.
local function layout(win, buf)
  local width = vim.api.nvim_win_get_width(win)
  local free = vim.api.nvim_win_get_height(win) - scene.content_height(buf) - 1
  local chosen = SETS[#SETS]
  for _, set in ipairs(SETS) do
    if set >= width then
      chosen = set
      break
    end
  end
  local ok, art = pcall(require, "locktrains.art.w" .. chosen)
  if not ok then
    return nil
  end

  local h = math.min(art.height, free * 2)
  h = h - h % 2
  local top = art.height - h
  if top > art.land.y - MIN_SKY then
    return nil -- not even the town fits
  end
  local w = math.min(art.width, width)
  local left = math.floor((art.width - w) / 2)

  -- Sky colors by art row
  local sky = scene.sky_colors(art)

  -- Today's moon, moved down if the crop would cut it
  local sprite = scene.moon_sprite(art)
  local cx, cy = art.moon.center[1], art.moon.center[2]
  local moon_top = math.max(art.moon.y - cy, top + 1)

  return {
    art = art,
    w = w,
    h = h,
    rows = h / 2,
    left = left,
    top = top,
    pad = math.floor((width - w) / 2),
    sky = sky,
    fb = {},
    moon = { sprite = sprite, x = art.moon.x - cx, y = moon_top },
  }
end

function M.stop()
  local s = state
  state = nil
  if not s then
    return
  end
  if s.timer then
    s.timer:stop()
    s.timer:close()
  end
  if s.float and vim.api.nvim_win_is_valid(s.float) then
    vim.api.nvim_win_close(s.float, true)
  end
  if s.buf and vim.api.nvim_buf_is_valid(s.buf) then
    vim.api.nvim_buf_delete(s.buf, { force = true })
  end
end

local function tick()
  local s = state
  if not s then
    return
  end
  -- Stop once the welcome screen is gone from its window
  if
    not vim.api.nvim_win_is_valid(s.win)
    or vim.api.nvim_win_get_buf(s.win) ~= s.dashboard
    or not vim.api.nvim_win_is_valid(s.float)
  then
    M.stop()
    return
  end
  local t = (vim.uv.hrtime() - s.start) / 1e9 + s.offset
  local lines = frame(s, t)
  if not lines then
    return
  end
  vim.api.nvim_buf_clear_namespace(s.buf, ns, 0, -1)
  for row, chunks in ipairs(lines) do
    vim.api.nvim_buf_set_extmark(s.buf, ns, row - 1, 0, {
      virt_text = chunks,
      virt_text_pos = "overlay",
      virt_text_win_col = s.pad,
    })
  end
end

-- Show the scene at the bottom of window `win`, which shows the welcome
-- screen buffer `buf`
function M.start(win, buf)
  -- Keep the clock when redrawing (e.g. after a resize), so the train
  -- carries on instead of starting over
  local started = state and state.start
  M.stop()
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local s = layout(win, buf)
  if not s then
    return
  end
  s.win, s.dashboard = win, buf
  s.start = started or vim.uv.hrtime()
  -- Begin with a train already on its way in
  s.offset = 1.5

  s.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[s.buf].bufhidden = "wipe"
  local blank = {}
  for i = 1, s.rows do
    blank[i] = ""
  end
  vim.api.nvim_buf_set_lines(s.buf, 0, -1, false, blank)

  local width = vim.api.nvim_win_get_width(win)
  s.float = vim.api.nvim_open_win(s.buf, false, {
    relative = "win",
    win = win,
    row = vim.api.nvim_win_get_height(win) - s.rows,
    col = 0,
    width = width,
    height = s.rows,
    style = "minimal",
    -- No border, whatever 'winborder' says
    border = "none",
    focusable = false,
    noautocmd = true,
    zindex = scene.zindex(win),
  })
  -- Outside the art (a window wider than the widest set): the night sky
  local edge = hl_for(s.sky[s.top], s.sky[s.top])
  vim.wo[s.float].winhighlight = "Normal:" .. edge .. ",EndOfBuffer:" .. edge

  state = s
  s.timer = vim.uv.new_timer()
  s.timer:start(0, math.floor(1000 / FPS), vim.schedule_wrap(tick))
end

-- Redo the layout, e.g. after the window was resized
function M.refresh()
  if state then
    M.start(state.win, state.dashboard)
  end
end

return M
