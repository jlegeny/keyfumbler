local Line = require 'line'
local lines = require 'lines'

local RayCaster = {}

function vector_intersects_line(vector, line)
  local norm_x, norm_y = Line.fast_norm(vector)
  local dota = (line.ax - vector.ax) * norm_x + (line.ay - vector.ay) * norm_y
  local dotb = (line.bx - vector.ax) * norm_x + (line.by - vector.ay) * norm_y

  local norm_xl, norm_yl = Line.fast_norm(line)
  local dot = (vector.ax - line.ax) * norm_xl + (vector.ay - line.ay) * norm_yl
  return (dota < 0 and dotb > 0) and dot > 0
end

RayCaster.collisions = function(map, vector)
  local collisions = {}
  for id, wall in pairs(map.walls) do
    if vector_intersects_line(vector, wall.line) then
      local int_x, int_y = lines.intersection(vector, wall.line)
      table.insert(collisions, {
        x = int_x,
        y = int_y,
        sqd = (int_x - vector.ax) ^ 2 + (int_y - vector.ay) ^ 2
      })
    end
  end

  return collisions
end

RayCaster.closest_collision = function(collisions)
  local closest = collisions[1]
  if #collisions == 1 then
    return closest
  end
  for i = 2, #collisions do
    if collisions[i].sqd < closest.sqd then
      closest = collisions[i]
    end
  end
  return closest
end

return RayCaster
