-- What happens in the scene, shared by both ways of drawing it (kitty images
-- and text): which train is where, its doors, and the moon's phase. Timings
-- and easing are the iPhone tweak's (LockTrains, Scene/LTSceneView.m).

local M = {}

-- The trains in the order they come, as on the phone
M.TURNS = { "mxa-right", "mx-left", "mx-right", "mxa-left" }

-- Where the train is in its round at `t` seconds: the train's name, the x
-- of its back end along the line (nil while out of sight) and the doors'
-- frame (0: shut). Braking in evenly, standing with the doors opening and
-- closing, then pulling away evenly. It comes in at `from` and leaves at
-- `to` (default: the art's own, just outside its edges; see M.route).
function M.train_at(art, t, from, to)
  local r = art.motion.round
  local round = r.arriving + r.opening + r.open + r.closing + r.waiting + r.leaving + r.empty
  local name = M.TURNS[math.floor(t / round) % #M.TURNS + 1]
  local s = t % round
  local platform = art.motion.platform
  from, to = from or art.motion.from, to or art.motion.to
  local frames = art.doors.frames

  if s < r.arriving then
    local u = s / r.arriving
    return name, from + (platform - from) * (1 - (1 - u) * (1 - u)), 0
  end
  s = s - r.arriving
  if s < r.opening then
    return name, platform, math.min(frames, math.floor(s / r.opening * frames) + 1)
  end
  s = s - r.opening
  if s < r.open then
    return name, platform, frames
  end
  s = s - r.open
  if s < r.closing then
    return name, platform, math.max(0, frames - math.floor(s / r.closing * frames) - 1)
  end
  s = s - r.closing
  if s < r.waiting then
    return name, platform, 0
  end
  s = s - r.waiting
  if s < r.leaving then
    local u = s / r.leaving
    return name, platform + (to - platform) * u * u, 0
  end
  return name, nil, 0
end

-- Where trains come in and leave when only `width` art pixels in the
-- middle of the scene are shown: just outside those, as on the phone, where
-- they come from right off the screen's edge (not from the edge of a wider
-- picture, which they would have to cross in the same time)
function M.route(art, width)
  local motion = art.motion
  local margin = -motion.from - motion.length
  local center = art.width / 2
  width = math.min(width, art.width)
  return center - width / 2 - motion.length - margin, center + width / 2 + margin
end

-- The train's top left corner in art pixels, for its x along the line
function M.train_position(art, name, along)
  if art.trains[name].heading ~= 1 then
    along = art.width - along - art.motion.length
  end
  return math.floor(along + 0.5) + art.train.x, art.train.y
end

-- The moon's phase today, 0 to 1 (new moon to new moon), as on the phone
function M.moon_phase()
  local month = 29.530588853 * 86400
  return ((os.time() - 947182440) % month) / month
end

-- Today's moon picture
function M.moon_sprite(art)
  local phases = art.moon.phases
  return phases[math.floor(M.moon_phase() * #phases + 0.5) % #phases + 1]
end

-- a + (b - a) * f, per channel, for 0xRRGGBB colors
function M.mix(a, b, f)
  local function channel(shift)
    local x = math.floor(a / shift) % 256
    local y = math.floor(b / shift) % 256
    return math.floor(x + (y - x) * f + 0.5)
  end
  return channel(65536) * 65536 + channel(256) * 256 + channel(1)
end

-- The sky's color for each art row, from the gradient
function M.sky_colors(art)
  local g = art.gradient
  local sky = {}
  for y = 0, art.height - 1 do
    local f = math.max(0, math.min(1, (y - g.from) / math.max(1, g.to - g.from)))
    sky[y] = M.mix(g.colors[1], g.colors[2], f)
  end
  return sky
end

-- The stacking order for the scene's window: just above the welcome screen,
-- which is a floating window itself when opened after startup
function M.zindex(win)
  local config = vim.api.nvim_win_get_config(win)
  if config.relative ~= "" then
    return (config.zindex or 50) + 1
  end
  return 10
end

-- The last line of the welcome screen buffer that has something on it
function M.content_height(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i = #lines, 1, -1 do
    if lines[i]:find "%S" then
      return i
    end
  end
  return 0
end

return M
