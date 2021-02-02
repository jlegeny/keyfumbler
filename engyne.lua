local palette = require 'palette'

local engyne = {}

local default_font = love.graphics.newFont("IBMPlexMono-SemiBold.ttf", 12)
local small_font = love.graphics.newFont("IBMPlexMono-SemiBold.ttf", 8)

function get_color(min, max, intensity)
  local dr = max[1] - min[1]
  local dg = max[2] - min[2]
  local db = max[3] - min[3]

  local step = (intensity / 7) ^ 2.2

  return {min[1] + dr * step, min[2] + dg * step, min[3] + dg * step}
end

engyne.release = function()
  default_font:release()
  small_font:release()
end

engyne.set_editor_color = function(color, opacity)
  if opacity == nil then
    opacity = 100
  end

  local c = {1, 0, 1}
  local a = opacity / 100

  if color == 'red' then
    c = { 1, 0, 0 }
  elseif color == 'green' then
    c = { 0, 1, 0 }
  elseif color == 'fuchsia' then
    c = { 1, 0, 1 }
  elseif color == 'blue' then
    c = { 0, 0.3, 1 }
   else
    return false
  end

  love.graphics.setColor(c[1], c[2], c[3], a)
  return true
end

engyne.set_color = function(color, intensity)
  local int = intensity
  if int == nil then
    int = 4
  end

  local c = {1, 0, 1}

  if palette[color] == nil then
    if color == 'darkgrey' then
      c = palette['grey'][int * 4 + 1]
    elseif color == 'lightgrey' then
      c = palette['grey'][int * 4 + 31]
    elseif engyne.set_editor_color(color, intensity) then
      return
    else
      print('Unknown color "', color, '"')
      love.event.quit(1)
    end
  else
    c = palette[color][int]
  end

  love.graphics.setColor(c[1], c[2], c[3], 1)
end

engyne.reset_color = function()
  love.graphics.setColor(1, 1, 1, 1)
end

engyne.hash_color = function(seed, alpha)
  if alpha == nil then
    alpha = 1
  end
  local a = 1103515245
  local c = 12345
  local m = 2 ^ 16

  local red = (a * seed + c) % m;
  local green = (a * red + c) % m;
  local blue = (a * green + c) % m;

  love.graphics.setColor((red / m), (green / m), (blue / m), alpha)
end

engyne.util = {}

engyne.util.make_set = function(t)
  local set = {}
  for _, value in pairs(t) do
    set[value] = true
  end
  return set
end

engyne.set_default_font = function()
  love.graphics.setFont(default_font)
end

engyne.set_small_font = function()
  love.graphics.setFont(small_font)
end

return engyne
