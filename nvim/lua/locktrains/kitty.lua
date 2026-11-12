-- LockTrains with kitty's graphics protocol: the scene as real images, at
-- the screen's own resolution.
--
-- The scene fills the whole welcome screen: the starry sky behind the menu,
-- the town and the tram stop along the bottom.
--
-- How it fits together:
--   * The art (lua/locktrains/art/wide.lua) is a big scene, wider and taller
--     than a terminal, with the trains at a fixed size. Each art pixel is
--     shown as an exact k×k block of screen pixels, k chosen so a train is
--     about TRAIN_ROWS rows tall whatever the font size; the scene is cut to
--     the window around that (centered, the sky trimmed at the top). kitty
--     smooths images it has to scale, so they are made at their final size
--     instead, which keeps the pixel art sharp.
--   * Each picture is written raw (RGBA) to a temporary file that kitty
--     reads and deletes (t=t), so no image data goes through tmux.
--   * A 1×1 transparent "anchor" image is shown with a Unicode placeholder
--     character in a one-cell floating window at the welcome screen's top
--     left corner. tmux and Neovim move that like any text.
--   * Every layer is a placement relative to the anchor, by cells plus a
--     pixel offset, with its own z-index: the background (sky, stars, moon,
--     town), the train, its doors, and the platform in front.
--   * Animating only re-places the train and its doors: a few bytes a
--     frame, smooth to the pixel. kitty does the drawing.
--
-- Placements have negative z-indexes, so they are drawn below text: the
-- menu shows on top of the sky. While a floating window (e.g. the file
-- picker) covers the scene, it is hidden.
--
-- There are two scenes, which can be shown at the same time:
--   dashboard  the whole night scene, filling the welcome screen
--   strip      just the town, the overhead wires, the platform and the
--              trains, in a few rows at the bottom while editing (:Trains,
--              see strip.lua); no sky, so the editor's background shows
--              through above the roofs

local scene = require "locktrains.scene"

local M = {}

-- The art of each scene: the whole night scene for the welcome screen, and
-- only the town, much wider, for the strip (scaled up less, it needs more
-- art pixels to fill a very wide terminal)
local ART = { dashboard = "locktrains.art.wide", strip = "locktrains.art.strip" }
-- Frames a second; a frame only sends anything if something moved
local FPS = 30
-- How tall a train is on the welcome screen, in rows of text (about: the art
-- is only enlarged by whole numbers)
local TRAIN_ROWS = 4
-- Image ids, a range for each scene so both can be shown at once. The
-- anchor's id must fit in a 24-bit color (the placeholder's); the scene's
-- pictures follow it, and its twinkling stars' animations from 0x1000 on.
local BASE = { dashboard = 0x4c5400, strip = 0x4c9400 }
local function id_range(base)
  return { anchor = base, background = base + 1, platform = base + 2, sprites = base + 16, stars = base + 0x1000 }
end
local Z = { background = -1000, stars = -950, train = -900, lights = -850, doors = -800, platform = -700 }

-- Twinkling stars: each star's bright pixels are placements of a tiny
-- animation (one per star group and color), which kitty plays by itself.
-- Their placement ids start at STAR_PID.
local STAR_PID = 1000
-- Frames in one twinkle (brightening and dimming once)
local TWINKLE_FRAMES = 16
-- The stars' bright colors; their darker halo pixels stay still
local TWINKLE_COLORS = {
  [0x575860] = true,
  [0x71839b] = true,
  [0x738091] = true,
  [0x81b29a] = true,
  [0x8ebaa4] = true,
  [0xaeafb0] = true,
  [0xbebebe] = true,
  [0xcdcecf] = true,
}

-- The running scenes, by name ("dashboard", "strip")
local scenes = {}

--------------------------------------------------------------------------------
-- Talking to kitty
--------------------------------------------------------------------------------

local function send(data)
  if vim.api.nvim_ui_send then
    vim.api.nvim_ui_send(data)
  else
    io.stdout:write(data)
  end
end

-- In tmux, commands go through its passthrough (needs `allow-passthrough
-- on`), which drops some when thousands come at once (the stars at start).
-- So there they are queued and sent BATCH at a time, every few milliseconds.
local BATCH = 50
local queue, head, flushing = {}, 1, false
-- Read once: vim.env can't be used in a timer's own callback (fast_frame)
local IN_TMUX = vim.env.TMUX ~= nil

local function passthrough(data)
  return "\27Ptmux;" .. data:gsub("\27", "\27\27") .. "\27\\"
end

-- While a frame is made in the timer's own callback (see fast_frame), the
-- commands are collected here instead of sent
local sink

local function flush()
  local last = math.min(head + BATCH - 1, #queue)
  send(table.concat(queue, "", head, last))
  head = last + 1
  if head <= #queue then
    vim.defer_fn(flush, 5)
  else
    queue, head, flushing = {}, 1, false
  end
end

local function write(data)
  if sink then
    sink[#sink + 1] = IN_TMUX and passthrough(data) or data
    return
  end
  if not IN_TMUX then
    send(data)
    return
  end
  queue[#queue + 1] = passthrough(data)
  if not flushing then
    flushing = true
    vim.schedule(flush)
  end
end

-- A graphics command; `keys` in a fixed order, so equal commands compare equal
local function command(keys, payload)
  local parts = {}
  for _, kv in ipairs(keys) do
    parts[#parts + 1] = kv[1] .. "=" .. kv[2]
  end
  return "\27_G" .. table.concat(parts, ",") .. (payload and (";" .. payload) or "") .. "\27\\"
end

-- Whether the scene can be shown with images here: kitty, on this machine
-- (kitty reads the pictures from local files)
function M.available()
  if vim.env.SSH_CONNECTION or vim.env.SSH_CLIENT then
    return false
  end
  return vim.env.KITTY_WINDOW_ID ~= nil or (vim.env.TERM or ""):find "kitty" ~= nil
end

-- The size of a cell in screen pixels, from the terminal (via snacks)
local function cell_size()
  local ok, terminal = pcall(require, "snacks.image.terminal")
  if not ok then
    return nil
  end
  local size = terminal.size()
  if not size or size.width == 0 then
    return nil
  end
  return math.floor(size.cell_width + 0.5), math.floor(size.cell_height + 0.5)
end

--------------------------------------------------------------------------------
-- Pictures
--------------------------------------------------------------------------------

local CLEAR = "\0\0\0\0"
local rgba_cache = {}

local function rgba(color)
  local s = rgba_cache[color]
  if not s then
    s = string.char(math.floor(color / 65536) % 256, math.floor(color / 256) % 256, color % 256, 255)
    rgba_cache[color] = s
  end
  return s
end

-- Where the pictures are written for kitty to read. kitty only deletes files
-- in a temporary folder with "tty-graphics-protocol" in their name.
local TMP = (vim.env.TMPDIR or "/tmp"):gsub("/$", "")
local PREFIX = "tty-graphics-protocol-locktrains-"

-- Remove pictures kitty never read (it quit before it could), older than a
-- minute so ones being read now are left alone
local function remove_stale()
  local now = os.time()
  for name, kind in vim.fs.dir(TMP) do
    if kind == "file" and vim.startswith(name, PREFIX) then
      local path = TMP .. "/" .. name
      local stat = vim.uv.fs_stat(path)
      if stat and now - stat.mtime.sec > 60 then
        os.remove(path)
      end
    end
  end
end

-- Upload a picture given as rows of runs ({count, color or nil}, ...) at art
-- resolution, enlarged k times
local function upload(id, width, height, rows, k)
  local data = {}
  for _, runs in ipairs(rows) do
    local line = {}
    for i = 1, #runs, 2 do
      line[#line + 1] = string.rep(runs[i + 1] and rgba(runs[i + 1]) or CLEAR, runs[i] * k)
    end
    line = table.concat(line)
    for _ = 1, k do
      data[#data + 1] = line
    end
  end
  local path = string.format("%s/%s%d-%d.rgba", TMP, PREFIX, id, vim.uv.hrtime())
  local file = assert(io.open(path, "wb"))
  file:write(table.concat(data))
  file:close()
  write(command({
    { "a", "t" },
    { "f", 32 },
    { "s", width * k },
    { "v", height * k },
    { "t", "t" },
    { "i", id },
    { "q", 2 },
  }, vim.base64.encode(path)))
  -- kitty deletes an image whose (relative) placements are all gone, which
  -- happens when the screen is cleared. A virtual placement isn't affected
  -- by clearing and is never shown, so it keeps the image for placing again.
  write(command {
    { "a", "p" },
    { "U", 1 },
    { "i", id },
    { "p", 2 },
    { "c", 1 },
    { "r", 1 },
    { "q", 2 },
  })
end

-- A sprite's rows as runs with colors (nil: transparent)
local function sprite_rows(art, sprite)
  local rows = {}
  for r, runs in ipairs(sprite.rows) do
    local out = {}
    for i = 1, #runs, 2 do
      out[#out + 1] = runs[i]
      out[#out + 1] = runs[i + 1] ~= 0 and art.palette[runs[i + 1]] or false
    end
    rows[r] = out
  end
  return rows
end

-- The image id of a sprite, uploading it the first time
local function sprite_image(s, key)
  local id = s.images[key]
  if not id then
    local sprite = s.art.sprites[key]
    id = s.ids.sprites + vim.tbl_count(s.images)
    upload(id, sprite.w, sprite.h, sprite_rows(s.art, sprite), s.k)
    s.images[key] = id
  end
  return id
end

-- Upload a twinkling star pixel as animation `id`: one art pixel (k×k
-- screen pixels) going from dim to `color` and back over TWINKLE_FRAMES
-- frames, at the phone's speed and starting at `phase`, against `sky`.
-- kitty loops it by itself, so twinkling costs nothing here.
local function twinkle(s, id, color, sky, phase)
  local art, k = s.art, s.k
  local period = 2 * math.pi / art.stars.speed * 1000 -- milliseconds
  local gap = math.floor(period / TWINKLE_FRAMES + 0.5)
  for f = 1, TWINKLE_FRAMES do
    local level = 0.5 + 0.5 * math.sin(2 * math.pi * (f - 1) / TWINKLE_FRAMES + phase)
    -- Never fully gone: from a quarter of the way to full brightness
    local c = scene.mix(sky, color, 0.25 + 0.75 * level)
    local data = vim.base64.encode(string.rep(rgba(c), k * k))
    local keys = f == 1 and { { "a", "t" }, { "i", id } } or { { "a", "f" }, { "i", id }, { "z", gap } }
    vim.list_extend(keys, { { "f", 32 }, { "s", k }, { "v", k }, { "t", "d" }, { "q", 2 } })
    write(command(keys, data))
  end
  -- The first frame's gap is set apart, then play it on a loop forever
  write(command { { "a", "a" }, { "i", id }, { "r", 1 }, { "z", gap }, { "q", 2 } })
  write(command { { "a", "a" }, { "i", id }, { "s", 3 }, { "v", 1 }, { "q", 2 } })
  -- Kept alive while not placed (see upload)
  write(command { { "a", "p" }, { "U", 1 }, { "i", id }, { "p", 2 }, { "c", 1 }, { "r", 1 }, { "q", 2 } })
end

-- The background in one picture: sky, stars, today's moon, the town and its
-- lit windows (everything behind the trains). Only the part in view. The
-- strip has only the town: the rest is left transparent.
local function background(s)
  local art, view = s.art, s.view
  local w, h = view.w, view.h
  local fb = {}
  local sky = art.gradient and scene.sky_colors(art)
  if sky then
    for y = 0, h - 1 do
      local c = sky[math.min(view.y + y, art.height - 1)]
      for x = 1, w do
        fb[y * w + x] = c
      end
    end
  end
  -- Bright star pixels in view, for twinkling: { x, y (in view), color, group }
  local stars = {}
  local function blit(key, x0, y0, group)
    local sprite = art.sprites[key]
    for r, runs in ipairs(sprite.rows) do
      local y, x = y0 + sprite.y + r - 1 - view.y, x0 + sprite.x - view.x
      for i = 1, #runs, 2 do
        local count, color = runs[i], runs[i + 1]
        if color ~= 0 and y >= 0 and y < h then
          local c = art.palette[color]
          for dx = 0, count - 1 do
            if x + dx >= 0 and x + dx < w then
              fb[y * w + x + dx + 1] = c
              if group and TWINKLE_COLORS[c] then
                stars[#stars + 1] = { x + dx, y, c, group }
              end
            end
          end
        end
        x = x + count
      end
    end
  end
  if sky then
    for g, group in ipairs(art.stars.groups) do
      blit(group.sprite, group.x, group.y, g)
    end
    blit(scene.moon_sprite(art), s.moon_x, s.moon_y)
  end
  blit(art.land.sprite, art.land.x, art.land.y)
  for _, wnd in ipairs(art.windows) do
    blit(wnd.sprite, wnd.x, wnd.y)
  end

  -- The twinkling stars: those still showing (not behind the moon or the
  -- town), each a placement of its group's animation in its color
  s.stars = {}
  local images = {}
  for _, star in ipairs(stars) do
    local x, y, c, g = star[1], star[2], star[3], star[4]
    if fb[y * w + x + 1] == c then
      local skyc = sky[math.min(view.y + y, art.height - 1)]
      local key = table.concat({ g, c, skyc }, ":")
      if not images[key] then
        images[key] = s.ids.stars + vim.tbl_count(images)
        twinkle(s, images[key], c, skyc, art.stars.groups[g].phase)
      end
      s.stars[#s.stars + 1] = { id = images[key], x = view.x + x, y = view.y + y }
    end
  end
  s.star_images = images

  local rows = {}
  for y = 0, h - 1 do
    local runs, last, count = {}, nil, 0
    for x = 1, w do
      local c = fb[y * w + x] or false -- false: transparent (the strip's sky)
      if c == last then
        count = count + 1
      else
        if count > 0 then
          runs[#runs + 1], runs[#runs + 2] = count, last
        end
        last, count = c, 1
      end
    end
    runs[#runs + 1], runs[#runs + 2] = count, last
    rows[y + 1] = runs
  end
  upload(s.ids.background, w, h, rows, s.k)
end

--------------------------------------------------------------------------------
-- Placing
--------------------------------------------------------------------------------

-- What is placed is remembered by image and placement id together (most
-- images have one placement, 1; the twinkling stars' have many)
local function key_of(id, pid)
  return id * 65536 + pid
end

-- Show image `id` with its top left corner at art pixel (ax, ay), cut to the
-- scene's area. `iw`, `ih`: the image's size in art pixels; `pid`: the
-- placement's id (default 1).
local function place(s, id, ax, ay, iw, ih, z, pid)
  pid = pid or 1
  local k = s.k
  local px, py = ax * k - s.crop_x + s.off_x, ay * k - s.crop_y + s.off_y
  local sx, sy, sw, sh = 0, 0, iw * k, ih * k
  if px < 0 then
    sx, sw, px = -px, sw + px, 0
  end
  if py < 0 then
    sy, sh, py = -py, sh + py, 0
  end
  sw = math.min(sw, s.area_w - px)
  sh = math.min(sh, s.area_h - py)
  if sw <= 0 or sh <= 0 then
    return false
  end
  -- The area may start right of the window's edge (see side_floats)
  px = px + s.left
  local h, v = math.floor(px / s.cw), math.floor(py / s.ch)
  local cmd = command {
    { "a", "p" },
    { "i", id },
    { "p", pid },
    { "P", s.ids.anchor },
    { "Q", 1 },
    { "H", h },
    { "V", v },
    { "X", px - h * s.cw },
    { "Y", py - v * s.ch },
    { "x", sx },
    { "y", sy },
    { "w", sw },
    { "h", sh },
    { "z", z },
    { "C", 1 },
    { "q", 2 },
  }
  local key = key_of(id, pid)
  if s.placed[key] ~= cmd then
    write(cmd)
    s.placed[key] = cmd
  end
  return true
end

-- Take placement `pid` (default 1) of image `id` off the screen, keeping the
-- image for later. Only that placement is deleted: deleting all of an
-- image's placements would also delete the virtual one that keeps the image
-- alive (see upload).
local function unplace(s, id, pid)
  pid = pid or 1
  local key = id and key_of(id, pid)
  if key and s.placed[key] then
    write(command { { "a", "d" }, { "d", "i" }, { "i", id }, { "p", pid }, { "q", 2 } })
    s.placed[key] = nil
  end
end

--------------------------------------------------------------------------------
-- The scene
--------------------------------------------------------------------------------

-- How tall a train's cars are in art pixels: the rows where the picture is
-- more than half its width wide, so not the pantograph above them
local function body_height(art)
  local sprite = art.sprites[art.trains[scene.TURNS[1]].sprite]
  local rows = 0
  for _, runs in ipairs(sprite.rows) do
    local opaque = 0
    for i = 1, #runs, 2 do
      if runs[i + 1] ~= 0 then
        opaque = opaque + runs[i]
      end
    end
    if opaque > sprite.w / 2 then
      rows = rows + 1
    end
  end
  return math.max(1, rows)
end

-- The strip's part of the scene, in art rows: from the top of the town (its
-- tallest roof) to the bottom of the trains' wheels. The ground below that
-- is shown only if there's room.
local function strip_rows(art)
  local land = art.sprites[art.land.sprite]
  local train = art.sprites[art.trains[scene.TURNS[1]].sprite]
  return art.land.y + land.y, art.train.y + train.y + train.h
end

-- Whether window `win` is a scene's anchor
local function is_anchor(win)
  for _, s in pairs(scenes) do
    if s.float == win then
      return true
    end
  end
  return false
end

-- Floating windows standing along a side of window `win`, at least as tall
-- as it (a minimap, like mini.map's): the strip leaves their columns free
-- instead of hiding behind them. Returns the columns to leave free on the
-- left and on the right, and those windows (as a set).
local function side_floats(win)
  local top, left = unpack(vim.api.nvim_win_get_position(win))
  local bottom = top + vim.api.nvim_win_get_height(win)
  local width = vim.api.nvim_win_get_width(win)
  local right = left + width
  local free_left, free_right, wins = 0, 0, {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(w)
    if w ~= win and config.relative ~= "" and not config.hide and not is_anchor(w) then
      local row, col = unpack(vim.api.nvim_win_get_position(w))
      local w_width = vim.api.nvim_win_get_width(w)
      local tall = row <= top and row + vim.api.nvim_win_get_height(w) >= bottom
      if tall and w_width < width / 2 and col < right and col + w_width > left then
        if col + w_width >= right then
          free_right = math.max(free_right, right - col)
          wins[w] = true
        elseif col <= left then
          free_left = math.max(free_left, col + w_width - left)
          wins[w] = true
        end
      end
    end
  end
  return free_left, free_right, wins
end

-- Pick the scale and the part of the scene `mode` shows in window `win`.
-- Each art pixel is k×k screen pixels:
--   dashboard  k making a train about TRAIN_ROWS rows tall; the scene cut
--              to the window, centered, keeping its bottom
--   strip      the largest k that fits the town and the trains in the
--              window's height; the sky above them cut off
-- Returns nil if it can't be shown.
local function layout(win, mode)
  local cw, ch = cell_size()
  if not cw then
    return nil
  end
  local art = require(ART[mode])
  local area_w = vim.api.nvim_win_get_width(win) * cw
  local area_h = vim.api.nvim_win_get_height(win) * ch
  local k, crop_y
  local free_left, free_right = 0, 0
  if mode == "strip" then
    free_left, free_right = side_floats(win)
    area_w = area_w - (free_left + free_right) * cw
    local top, bottom = strip_rows(art)
    k = math.max(1, math.floor(area_h / (bottom - top)))
    -- From the roofs down, or the whole bottom of the scene if it fits
    crop_y = math.max(0, math.min(top * k, art.height * k - area_h))
  else
    k = math.max(1, math.floor(TRAIN_ROWS * ch / body_height(art) + 0.5))
    crop_y = math.max(0, art.height * k - area_h)
  end
  local scene_w, scene_h = art.width * k, art.height * k

  local s = {
    mode = mode,
    strip = mode == "strip",
    ids = id_range(BASE[mode]),
    art = art,
    k = k,
    cw = cw,
    ch = ch,
    area_w = area_w,
    area_h = area_h,
    -- Columns left free for floats along the sides; the area starts `left`
    -- screen pixels right of the window's edge
    free_left = free_left,
    free_right = free_right,
    left = free_left * cw,
    -- Screen pixels of the scene cut off at the left and top, or room left
    -- around it in a window larger than the whole scene
    crop_x = math.max(0, math.floor((scene_w - area_w) / 2)),
    crop_y = crop_y,
    off_x = math.max(0, math.floor((area_w - scene_w) / 2)),
    off_y = math.max(0, area_h - scene_h),
    images = {},
    placed = {},
  }
  -- The part in view, in art pixels
  local x0, y0 = math.floor(s.crop_x / k), math.floor(s.crop_y / k)
  s.view = {
    x = x0,
    y = y0,
    w = math.min(art.width - x0, math.ceil((s.crop_x + area_w) / k) - x0),
    h = math.min(art.height - y0, math.ceil((s.crop_y + area_h) / k) - y0),
  }
  -- Today's moon, where it is on the phone: across 84% of the view, low in
  -- the sky, moved down if the view would cut it
  if art.moon then
    local cx, cy = art.moon.center[1], art.moon.center[2]
    s.moon_x = s.view.x + math.floor(s.view.w * 0.84) - cx
    s.moon_y = math.max(art.moon.y - cy, s.view.y + 2)
  end
  -- The trains come in and leave just outside what's shown
  s.from, s.to = scene.route(art, math.ceil(area_w / k))
  return s
end

-- The text cursor's block is drawn below images, which made the character
-- under it vanish into the sky. While a scene's window is focused, the
-- cursor is hidden: Neovim hides it if its highlight has blend=100.
local saved_guicursor

local function hide_cursor()
  if not saved_guicursor then
    saved_guicursor = vim.o.guicursor
    vim.api.nvim_set_hl(0, "LockTrainsHiddenCursor", { blend = 100, nocombine = true })
    vim.o.guicursor = "a:LockTrainsHiddenCursor"
  end
end

local function show_cursor()
  if saved_guicursor then
    vim.o.guicursor = saved_guicursor
    saved_guicursor = nil
  end
end

-- Whether window `win` shows one of the scenes
local function on_scene(win)
  for _, s in pairs(scenes) do
    if s.win == win then
      return true
    end
  end
  return false
end

-- Stop scene `mode` and delete its pictures
local function stop(mode)
  local s = scenes[mode]
  scenes[mode] = nil
  if not on_scene(vim.api.nvim_get_current_win()) then
    show_cursor()
  end
  if not s then
    return
  end
  if s.timer then
    s.timer:stop()
    s.timer:close()
  end
  if s.tty then
    vim.uv.fs_close(s.tty)
    s.tty = nil
  end
  if s.augroup then
    vim.api.nvim_del_augroup_by_id(s.augroup)
  end
  -- Deleting the images also deletes their placements
  for _, id in ipairs { s.ids.anchor, s.ids.background, s.ids.platform } do
    write(command { { "a", "d" }, { "d", "I" }, { "i", id }, { "q", 2 } })
  end
  for _, id in pairs(s.images) do
    write(command { { "a", "d" }, { "d", "I" }, { "i", id }, { "q", 2 } })
  end
  for _, id in pairs(s.star_images or {}) do
    write(command { { "a", "d" }, { "d", "I" }, { "i", id }, { "q", 2 } })
  end
  if s.float and vim.api.nvim_win_is_valid(s.float) then
    vim.api.nvim_win_close(s.float, true)
  end
  if s.buf and vim.api.nvim_buf_is_valid(s.buf) then
    vim.api.nvim_buf_delete(s.buf, { force = true })
  end
end

-- Place the twinkling stars: each bright star pixel, a placement of its
-- (group, color) animation
local function place_stars(s)
  for key, cmd in pairs(s.placed) do
    if key % 65536 >= STAR_PID and cmd ~= "" then
      s.placed[key] = ""
    end
  end
  s.stars_at = vim.uv.hrtime()
  for i, star in ipairs(s.stars) do
    place(s, star.id, star.x, star.y, 1, 1, Z.stars, STAR_PID + i)
  end
end

-- Place the pictures that don't move: the background and the platform, and
-- make the next frame place the train, its lamps and doors again too. What
-- is placed is marked as needing to be sent again, not forgotten: a picture
-- that later goes away (a lamp's next shimmer) must still be taken off.
-- With `stars`, the twinkling stars too (a thousand or so placements, so
-- they're sent again less often).
local function place_all(s, stars)
  for key in pairs(s.placed) do
    if key % 65536 < STAR_PID then
      s.placed[key] = ""
    end
  end
  s.placed_at = vim.uv.hrtime()
  place(s, s.ids.background, s.view.x, s.view.y, s.view.w, s.view.h, Z.background)
  local platform = s.art.sprites[s.art.platform.sprite]
  place(
    s,
    s.ids.platform,
    s.art.platform.x + platform.x,
    s.art.platform.y + platform.y,
    platform.w,
    platform.h,
    Z.platform
  )
  if stars then
    place_stars(s)
  end
end

-- Take everything off the screen, keeping the pictures for later
local function hide_all(s)
  for key in pairs(s.placed) do
    local id, pid = math.floor(key / 65536), key % 65536
    write(command { { "a", "d" }, { "d", "i" }, { "i", id }, { "p", pid }, { "q", 2 } })
  end
  s.placed = {}
end

-- In tmux: ask whether this Neovim's tmux window is the one on screen (the
-- active window of an attached session), and pause or carry on to match
local function check_visible(s)
  if s.checking then
    return
  end
  s.checking = true
  vim.system(
    { "tmux", "display-message", "-p", "-t", vim.env.TMUX_PANE, "#{window_active} #{session_attached}" },
    { text = true },
    function(result)
      vim.schedule(function()
        s.checking = false
        s.checked_at = vim.uv.hrtime()
        if scenes[s.mode] ~= s or not s.focus_lost then
          return
        end
        local active, attached = (result.stdout or ""):match "(%d+) (%d+)"
        local visible = result.code == 0 and active == "1" and tonumber(attached or 0) > 0
        if visible and s.paused then
          s.paused = false
          place_all(s, true)
        elseif not visible and not s.paused then
          s.paused = true
          hide_all(s)
        end
      end)
    end
  )
end

-- How often everything is placed again, in seconds: kitty drops placements
-- when the screen is cleared (Ctrl-L, tmux redrawing), and they come back
-- this way. The stars, many more placements, less often.
local REPLACE_EVERY = 2
local STARS_EVERY = 10

-- Whether a floating window (the file picker, ...) covers part of the
-- scene's window: the scene would show through its background. Split
-- windows next to it (a file tree) don't matter. The welcome screen only
-- minds the ones that can be focused; the strip any (the completion menu,
-- hover docs, which-key, ...).
local function covered(s)
  local top, left = unpack(vim.api.nvim_win_get_position(s.win))
  local bottom = top + vim.api.nvim_win_get_height(s.win)
  local right = left + vim.api.nvim_win_get_width(s.win)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= s.win and not is_anchor(win) and not (s.sides and s.sides[win]) then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" and (s.strip or config.focusable ~= false) and not config.hide then
        local row, col = unpack(vim.api.nvim_win_get_position(win))
        local height, width = vim.api.nvim_win_get_height(win), vim.api.nvim_win_get_width(win)
        if row < bottom and row + height > top and col < right and col + width > left then
          return true
        end
      end
    end
  end
  return false
end

-- Place the train where it is now, with its lamps and doors. `fast`: in
-- the timer's own callback (see fast_frame), where no picture can be
-- uploaded: a lamp's or door's picture not uploaded yet is left as it was.
local function move_train(s, fast)
  local art = s.art
  local t = (vim.uv.hrtime() - s.start) / 1e9 + s.offset
  local name, along, door = scene.train_at(art, t, s.from, s.to)
  local train = art.trains[name]
  local function image(key)
    if fast then
      return s.images[key]
    end
    return sprite_image(s, key)
  end

  local train_id = image(train.sprite)
  if not train_id then
    return
  end
  if s.train_id and s.train_id ~= train_id then
    unplace(s, s.train_id)
  end
  s.train_id = train_id

  local door_key = door > 0 and train.doors[door] or nil
  local door_id = door_key and image(door_key)
  if door_key and not door_id then
    door_key, door_id = s.door_key, s.door_id
  end
  if s.door_id and s.door_id ~= door_id then
    unplace(s, s.door_id)
  end
  s.door_id, s.door_key = door_id, door_key

  -- The lamps: one of their shimmering pictures, perSecond a second
  local lights = train.lights
  local light_key = along and lights and lights[math.floor(t * art.light.perSecond) % #lights + 1] or nil
  local light_id = light_key and image(light_key)
  if light_key and not light_id then
    light_key, light_id = s.light_key, s.light_id
  end
  if s.light_id and s.light_id ~= light_id then
    unplace(s, s.light_id)
  end
  s.light_id, s.light_key = light_id, light_key

  if not along then
    unplace(s, train_id)
    return
  end
  local x, y = scene.train_position(art, name, along)
  local sprite = art.sprites[train.sprite]
  if not place(s, train_id, x + sprite.x, y + sprite.y, sprite.w, sprite.h, Z.train) then
    unplace(s, train_id)
  end
  if light_id then
    local l = art.sprites[light_key]
    if not place(s, light_id, x + art.light.x + l.x, y + art.light.y + l.y, l.w, l.h, Z.lights) then
      unplace(s, light_id)
    end
  end
  if door_id then
    local d = art.sprites[door_key]
    place(s, door_id, x + art.doors.x + d.x, y + art.doors.y + d.y, d.w, d.h, Z.doors)
  end
end

-- Neovim runs nothing scheduled while it waits for the rest of a mapping
-- (<leader>, then up to 'timeoutlen'), or is otherwise busy, so the
-- frames stop. Then the timer moves the train itself, in its own callback,
-- where Neovim's API can't be used: the few commands are written straight
-- to the terminal (s.tty, see open_tty) instead of through Neovim. Only
-- moving what is already placed; everything else waits for the next
-- normal frame.
local function fast_frame(s)
  if s.paused or s.hidden or not s.tty then
    return
  end
  sink = {}
  local ok = pcall(move_train, s, true)
  local data = table.concat(sink)
  sink = nil
  if ok and data ~= "" then
    pcall(vim.uv.fs_write, s.tty, data)
  end
end

-- Open the terminal Neovim draws on, for fast_frame: tmux's pane, or the
-- terminal of Neovim's UI process (this one's parent). Asynchronous; until
-- then, and if it can't be found, the frames just wait as before.
local function open_tty(s)
  local cmd
  if IN_TMUX and vim.env.TMUX_PANE then
    cmd = { "tmux", "display-message", "-p", "-t", vim.env.TMUX_PANE, "#{pane_tty}" }
  else
    cmd = { "ps", "-o", "tty=", "-p", tostring(vim.uv.os_getppid()) }
  end
  local ok = pcall(vim.system, cmd, { text = true }, function(result)
    local name = vim.trim(result.stdout or "")
    if result.code ~= 0 or name == "" or name:find "?" then
      return
    end
    local path = name:sub(1, 1) == "/" and name or "/dev/" .. name
    -- Not as this process's controlling terminal
    local flags = vim.uv.constants.O_WRONLY + (vim.uv.constants.O_NOCTTY or 0)
    vim.uv.fs_open(path, flags, 0, function(_, fd)
      if not fd then
        return
      end
      if scenes[s.mode] == s then
        s.tty = fd
      else
        vim.uv.fs_close(fd)
      end
    end)
  end)
  return ok
end

local function tick(s)
  s.pending = nil
  if scenes[s.mode] ~= s then
    return
  end
  if
    not vim.api.nvim_win_is_valid(s.win)
    or vim.api.nvim_win_get_buf(s.win) ~= s.target
    or not vim.api.nvim_win_is_valid(s.float)
  then
    stop(s.mode)
    return
  end
  -- Paused while another tmux window is shown: placing anything now could
  -- draw it over that window. Checked again every second while Neovim is
  -- unfocused.
  if s.focus_lost and (vim.uv.hrtime() - (s.checked_at or 0)) / 1e9 > 1 then
    check_visible(s)
  end
  if s.paused then
    return
  end
  -- The cursor is hidden only while a scene's window has the focus
  if on_scene(vim.api.nvim_get_current_win()) then
    hide_cursor()
  else
    show_cursor()
  end
  -- A minimap opened or closed beside the strip: lay it out again
  if s.strip then
    local free_left, free_right, sides = side_floats(s.win)
    if free_left ~= s.free_left or free_right ~= s.free_right then
      M.show(s.mode, s.win, s.target)
      return
    end
    s.sides = sides
  end
  -- Hidden while a floating window covers the scene; running on with a
  -- file tree (or any split) next to it
  if covered(s) then
    if not s.hidden then
      hide_all(s)
      s.hidden = true
    end
    return
  end
  local now = vim.uv.hrtime()
  if s.hidden or (now - s.placed_at) / 1e9 > REPLACE_EVERY then
    local stars = s.hidden or (now - s.stars_at) / 1e9 > STARS_EVERY
    s.hidden = false
    place_all(s, stars)
  end
  move_train(s, false)
end

-- Show scene `mode` in window `win`, which shows buffer `buf` (the welcome
-- screen's, or the strip's empty one). The scene stops when the window
-- closes or shows another buffer. Called again (e.g. after a resize), it
-- fits the scene to the window again. Returns false if it can't be shown
-- with images.
function M.show(mode, win, buf)
  if not vim.api.nvim_win_is_valid(win) then
    stop(mode)
    return false
  end
  local s = layout(win, mode)
  local old = scenes[mode]
  -- Drawn again with nothing changed (the welcome screen redraws e.g. when
  -- its footer updates): keep everything as it is
  if
    s
    and old
    and old.win == win
    and old.k == s.k
    and old.area_w == s.area_w
    and old.area_h == s.area_h
    and old.left == s.left
    and vim.api.nvim_win_is_valid(old.float)
  then
    return true
  end
  -- Keep the clock, so the train carries on instead of starting over
  local started = old and old.start
  stop(mode)
  if not s then
    return false
  end
  s.win, s.target = win, buf
  s.start = started or vim.uv.hrtime()
  -- Begin with a train already on its way in
  s.offset = 1.5

  -- The anchor's window: one cell at the welcome screen's top left corner,
  -- holding the placeholder (U+10EEEE, row 0, column 0: both U+0305)
  s.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[s.buf].bufhidden = "wipe"
  local placeholder = "\u{10EEEE}\u{0305}\u{0305}"
  vim.api.nvim_buf_set_lines(s.buf, 0, -1, false, { placeholder })
  local ns = vim.api.nvim_create_namespace "locktrains-kitty"
  local anchor_hl = "LockTrainsAnchor_" .. mode
  vim.api.nvim_set_hl(0, anchor_hl, { fg = s.ids.anchor })
  vim.api.nvim_buf_set_extmark(s.buf, ns, 0, 0, { end_col = #placeholder, hl_group = anchor_hl })

  s.float = vim.api.nvim_open_win(s.buf, false, {
    relative = "win",
    win = win,
    row = 0,
    col = 0,
    width = 1,
    height = 1,
    style = "minimal",
    border = "none",
    focusable = false,
    noautocmd = true,
    zindex = scene.zindex(win),
  })

  -- The anchor: a transparent pixel, shown by the placeholder
  write(command({
    { "a", "T" },
    { "f", 32 },
    { "s", 1 },
    { "v", 1 },
    { "t", "d" },
    { "i", s.ids.anchor },
    { "p", 1 },
    { "U", 1 },
    { "c", 1 },
    { "r", 1 },
    { "q", 2 },
  }, vim.base64.encode(CLEAR)))

  -- No "~" for the welcome screen's empty lines: they'd show over the sky.
  -- Local to the welcome screen's buffer in that window, so a file opened
  -- there later gets the normal value.
  vim.api.nvim_set_option_value("fillchars", "eob: ", { scope = "local", win = win })

  -- The pictures behind and in front of the trains
  remove_stale()
  background(s)
  local platform = s.art.sprites[s.art.platform.sprite]
  upload(s.ids.platform, platform.w, platform.h, sprite_rows(s.art, platform), s.k)
  place_all(s, true)

  -- Losing focus doesn't stop the scene: kitty only draws images in the
  -- window they belong to, so another app or kitty tab in front is fine. In
  -- tmux, though, focus is also lost when another tmux window is shown in
  -- this kitty window, and the scene must not be drawn over that: pause
  -- until tmux says this window is (still) the one on screen.
  s.augroup = vim.api.nvim_create_augroup("LockTrainsKitty_" .. mode, { clear = true })
  vim.api.nvim_create_autocmd("FocusLost", {
    group = s.augroup,
    callback = function()
      if vim.env.TMUX and vim.env.TMUX_PANE then
        s.focus_lost = true
        s.paused = true
        check_visible(s)
      end
    end,
  })
  vim.api.nvim_create_autocmd("FocusGained", {
    group = s.augroup,
    callback = function()
      s.focus_lost = false
      s.paused = false
      place_all(s, true)
    end,
  })

  scenes[mode] = s
  s.timer = vim.uv.new_timer()
  -- A frame is scheduled (run when Neovim is free); if the last one still
  -- hasn't run after a frame and a half, the train is moved right here
  -- (fast_frame)
  local interval = math.floor(1000 / FPS)
  s.timer:start(0, interval, function()
    if scenes[s.mode] ~= s then
      return
    end
    local now = vim.uv.hrtime()
    if not s.pending then
      s.pending = now
      vim.schedule(function()
        tick(s)
      end)
    elseif (now - s.pending) / 1e6 > interval * 1.5 then
      fast_frame(s)
    end
  end)
  open_tty(s)
  return true
end

-- The art row where the overhead wires start (their poles' tops): the town
-- picture's first row with the poles' or wires' color in it
local WIRE_COLORS = { [0x39506d] = true, [0x738091] = true }
local function wires_top(art)
  local sprite = art.sprites[art.land.sprite]
  for r, runs in ipairs(sprite.rows) do
    for i = 2, #runs, 2 do
      if runs[i] ~= 0 and WIRE_COLORS[art.palette[runs[i]]] then
        return art.land.y + sprite.y + r - 1
      end
    end
  end
  return art.land.y
end

-- The row of window `win` where the scene's overhead wires start, or nil if
-- the scene can't be shown with images there. The welcome screen centers its
-- menu above it.
function M.wires_row(win)
  if not M.available() or not vim.api.nvim_win_is_valid(win) then
    return nil
  end
  local s = layout(win, "dashboard")
  if not s then
    return nil
  end
  return math.floor((wires_top(s.art) * s.k - s.crop_y + s.off_y) / s.ch)
end

-- Stop scene `mode`
function M.hide(mode)
  stop(mode)
end

-- The welcome screen's scene
function M.start(win, buf)
  return M.show("dashboard", win, buf)
end

function M.stop()
  stop "dashboard"
end

return M
