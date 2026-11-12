-- LockTrains on the welcome screen: the iPhone tweak's night scene, a town
-- with a tram stop, animated under the welcome screen's menu. A tram comes
-- in, brakes to the platform, opens and closes its doors, pulls away, and
-- the next one comes from the other side, under today's moon.
--
-- The art is homepi-admin's own pixel art (see nvim/scripts/locktrains-art.py)
-- and is drawn one of two ways:
--   kitty.lua  real images at the screen's resolution, in kitty
--   text.lua   "▀" characters, two art pixels a cell, anywhere else
--
-- Both stop as soon as the welcome screen is left.

local M = {}

local backend -- the module drawing the scene now

-- Show the scene at the bottom of window `win`, which shows the welcome
-- screen buffer `buf`
function M.start(win, buf)
  local kitty = require "locktrains.kitty"
  if kitty.available() and kitty.start(win, buf) then
    if backend and backend ~= kitty then
      backend.stop()
    end
    backend = kitty
    return
  end
  kitty.stop()
  local text = require "locktrains.text"
  text.start(win, buf)
  backend = text
end

function M.stop()
  if backend then
    backend.stop()
    backend = nil
  end
end

return M
