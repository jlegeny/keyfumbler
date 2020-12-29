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
        sqd = (int_x - vector.ax) ^ 2 + (int_y - vector.ay) ^ 2,
        id = id,
      })
    end
  end

  return collisions
end

function bsp_intersect(node, visited, prev, vector)
  print('visiting ' .. node.id)
  visited[node.id] = true

  local following = {}
  if not node.is_leaf then
    local norm_x, norm_y = Line.fast_norm(vector)

    local dota = (node.wall.line.ax - vector.ax) * norm_x + (node.wall.line.ay - vector.ay) * norm_y
    local dotb = (node.wall.line.bx - vector.ax) * norm_x + (node.wall.line.by - vector.ay) * norm_y

    local norm_xl, norm_yl = Line.fast_norm(node.wall.line)
    local dot = (vector.ax - node.wall.line.ax) * norm_xl + (vector.ay - node.wall.line.ay) * norm_yl

    if (dota < 0 and dotb > 0) and dot > 0 then
      local int_x, int_y = lines.intersection(vector, node.wall.line)
      table.insert(prev, {
        x = int_x,
        y = int_y,
        sqd = (int_x - vector.ax) ^ 2 + (int_y - vector.ay) ^ 2,
        id = node.ogid,
      })
      local following = bsp_intersect(node.back, visited, {}, vector)
      local prev_front = bsp_intersect(node.front, visited, {}, vector)
      for i = 1, #prev_front do
        following[#following + i] = prev_front[i]
      end
    elseif (dota < 0 and dotb < 0) then
      if visited[node.front.id] == nil then
        following = bsp_intersect(node.front, visited, prev, vector)
      end
    elseif (dota > 0 and dotb > 0) then
      if visited[node.back.id] == nil then
        following = bsp_intersect(node.back, visited, prev, vector)
      end
    else
      local following = bsp_intersect(node.back, visited, {}, vector)
      local prev_front = bsp_intersect(node.front, visited, {}, vector)
      for i = 1, #prev_front do
        following[#following + i] = prev_front[i]
      end
     end
  end

  for i = 1, #following do
    prev[#prev + i] = following[i]
  end

  if node.parent == nil then
    return prev
  end
  if visited[node.parent.id] == nil then
    return bsp_intersect(node.parent, visited, prev, vector)
  end

  return {}
end

RayCaster.fast_collisions = function(node, vector)
  print('\ndetecting collisions')
  return bsp_intersect(node, {}, {}, vector)
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

RayCaster.get_region_node = function(bsp, rx, ry)
  local node = bsp

  while not node.is_leaf do
    local dot = Line.point_dot(node.wall.line, rx, ry)
    if dot <= 0 then
      node = node.back
    else
      node = node.front
    end
  end

  return node
end

RayCaster.get_region = function(bsp, rx, ry)
  return RayCaster.get_region_node(bsp, rx, ry).id
end


return RayCaster
