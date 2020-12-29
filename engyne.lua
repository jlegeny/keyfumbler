local engyne = {}

local default_font = love.graphics.newFont("IBMPlexMono-SemiBold.ttf", 12)
local small_font = love.graphics.newFont("IBMPlexMono-SemiBold.ttf", 8)

local light_grey_min = {0.5, 0.5, 0.5}
local light_grey_max = {1, 1, 1}

function get_color(min, max, intensity)
  local dr = max[1] - min[1]
  local dg = max[2] - min[2]
  local db = max[3] - min[3]

  local step = intensity / 8

  return {min[1] + dr * step, min[2] + dg * step, min[3] + dg * step}
end

engyne.set_color = function(color, intensity)
  if intensity == nil then
    intensity = 0
  end

  if color == 'copper' then
    love.graphics.setColor(0.9, 0.4, 0.1, 1)
  elseif color == 'lightgrey' then
    local c = get_color(light_grey_min, light_grey_max, intensity)
    love.graphics.setColor(c[1], c[2], c[3], 1)
  elseif color == 'red' then
    love.graphics.setColor(1, 0.4, 0, 1)
  elseif color == 'moss' then
    love.graphics.setColor(0.2, 1, 0.6, 1)
  else
    print('Unknown color "', color, '"')
    love.event.quit(1)
  end
end

engyne.hash_color = function(seed)
  local a = 1103515245
  local c = 12345
  local m = 2 ^ 16

  local red = (a * seed + c) % m;
  local green = (a * red + c) % m;
  local blue = (a * green + c) % m;

  love.graphics.setColor((red / m), (green / m), (blue / m), 1)
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
