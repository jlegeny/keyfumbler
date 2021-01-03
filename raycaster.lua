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
  visited[node.id] = true

  local following = {}
  if not node.is_leaf then
    local norm_x, norm_y = Line.fast_norm(vector)

    local dota = (node.line.ax - vector.ax) * norm_x + (node.line.ay - vector.ay) * norm_y
    local dotb = (node.line.bx - vector.ax) * norm_x + (node.line.by - vector.ay) * norm_y

    local norm_xl, norm_yl = Line.fast_norm(nodeline)
    local dot = (vector.ax - node.line.ax) * norm_xl + (vector.ay - node.line.ay) * norm_yl

    if (dota < 0 and dotb > 0) and dot > 0 then
      local int_x, int_y = lines.intersection(vector, node.line)
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

RayCaster.fast_collisions = function(map, vector)
  local nodes = RayCaster.get_visible_ordered_nodes(map.bsp, vector.ax, vector.ay, vector.bx, vector.by)

  local collisions = {}
  local lx, ly = vector.ax, vector.ay

  for i, node in ipairs(nodes) do
    if not node.is_leaf then
      if vector_intersects_line(vector, node.line) or (
        node.is_split and vector_intersects_line(vector, lines.swapped(node.line))) then
        local int_x, int_y = lines.intersection(vector, node.line)
        -- find room in front
        local dx, dy = (vector.bx - vector.ax) / 100, (vector.by - vector.ay) / 100
        local hx, hy = int_x - dx, int_y - dy
        local room = RayCaster.get_region_node(map.bsp, hx, hy)
        local room_id
        if room == nil then
          room_id = nil
        else
          room_id = room.id
        end
        table.insert(collisions, {
          x = int_x,
          y = int_y,
          sqd = (int_x - vector.ax) ^ 2 + (int_y - vector.ay) ^ 2,
          id = node.ogid,
          room_id = room_id,
          is_split = node.is_split,
          ceiling_height = room.ceiling_height,
          floor_height = room.floor_height,
          ambient_light = room.ambient_light,
        })
        lx = int_x
        ly = int_y
        if not node.is_split then
          return collisions
        end
      end
    end
  end
  return collisions
end

RayCaster.is_cut_by_wall = function(map, line)
  local collisions = RayCaster.fast_collisions(map, line)
  for _, cc in pairs(collisions) do
    if not cc.is_split then
      return true
    end
  end
  return false
end

RayCaster.extended_collisions = function(map, vector)
  local collisions = RayCaster.fast_collisions(map, vector)
  -- light collisions
  local collisions_and_spots = {}
  --local spot_ds = {0.1, 0.25, 0.5, 0.75, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5}
  --local spot_ds = {1.6^-1, 1.6^-0.5, 1.6^0, 1.6^0.25, 1.6^0.5, 1.6^2, 1.6^3, 1.6^4 }
  local spot_ds = {2, 4}
  local next_spot = 1
  local nx, ny = Line.unit_vector(vector)
  for i = 1, #collisions do
    local col = collisions[i]
    while next_spot <= #spot_ds and spot_ds[next_spot] ^ 2 < col.sqd do
      local int_x = vector.ax + nx * spot_ds[next_spot]
      local int_y = vector.ay + ny * spot_ds[next_spot]
      table.insert(collisions_and_spots, {
        x = int_x,
        y = int_y,
        sqd = spot_ds[next_spot] ^ 2,
        id = 0,
        room_id = col.room_id,
        is_spot = true,
        ceiling_height = col.ceiling_height,
        floor_height = col.floor_height,
        ambient_light = col.ambient_light,
      })
      next_spot = next_spot + 1
    end
    table.insert(collisions_and_spots, col)
  end

  return collisions_and_spots
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
    local dot = Line.fast_dot(node.line, rx, ry)
    if dot <= 0 then
      node = node.back
    else
      node = node.front
    end
  end

  return node
end

RayCaster.get_region_id = function(bsp, rx, ry)
  return RayCaster.get_region_node(bsp, rx, ry).id
end

RayCaster.get_subtree_ids = function(node)
  if node.is_leaf then
    return { node.id }
  end

  local front = RayCaster.get_subtree_ids(node.front)
  local back = RayCaster.get_subtree_ids(node.back)

  local ids = {
    node.id
  }
  for i = 1, #front do
    table.insert(ids, front[i])
  end
  for i = 1, #back do
    table.insert(ids, back[i])
  end

  return ids
end

RayCaster.get_ordered_nodes = function(node, rx, ry, flip)
  if flip == nil then
    flip = false
  end

  if node.is_leaf then
    return {node}
  end

  local norm_x, norm_y = Line.fast_norm(node.line)
  local dot = (rx - node.line.ax) * norm_x + (ry - node.line.ay) * norm_y
 
  local front = RayCaster.get_ordered_nodes(node.front, rx, ry)

  local back = RayCaster.get_ordered_nodes(node.back, rx, ry)

  local ids = {}
  if dot > 0 then
    for i = 1, #front do
      table.insert(ids, front[i])
    end
    table.insert(ids, node)
    for i = 1, #back do
      table.insert(ids, back[i])
    end
  else
    for i = 1, #back do
      table.insert(ids, back[i])
    end
    table.insert(ids, node)
    for i = 1, #front do
      table.insert(ids, front[i])
    end
  end

  return ids
end

RayCaster.get_visible_ordered_nodes = function(node, rx, ry, vx, vy)
  if node.is_leaf then
    return {node}
  end

  local norm_x, norm_y = Line.fast_norm(node.line)
  local dot = (rx - node.line.ax) * norm_x + (ry - node.line.ay) * norm_y
  local dotv = (vx - node.line.ax) * norm_x + (vy - node.line.ay) * norm_y

  local front = {}
  if dot > 0 or dotv > dot then
    front = RayCaster.get_visible_ordered_nodes(node.front, rx, ry, vx, vy)
  end
  local back = {}
  if dot < 0 or dotv < dot then
    back = RayCaster.get_visible_ordered_nodes(node.back, rx, ry, vx, vy)
  end

  local ids = {}
  if dot > 0 then
    for i = 1, #front do
      table.insert(ids, front[i])
    end
    if dot > dotv then
      table.insert(ids, node)
    end
    for i = 1, #back do
      table.insert(ids, back[i])
    end
  else
    for i = 1, #back do
      table.insert(ids, back[i])
    end
    if dot < dotv then
      table.insert(ids, node)
    end
    for i = 1, #front do
      table.insert(ids, front[i])
    end
  end

  return ids
end

RayCaster.get_front_leave_ids = function(node, visited)
  if visited == nil then
    visited = {}
  end

  visited[node.id] = true

  if node.is_leaf then
    return {}
  end
  
  local ids = {}
  if visited[node.front.id] == nil then
    if node.front.is_leaf then
      table.insert(ids, node.front.id)
    else
      local front = RayCaster.get_front_leave_ids(node.front, visited)
      for i = 1, #front do
        table.insert(ids, front[i])
      end
    end
  end
  
  --if visited[node.back.id] == nil then
    --if not node.back.is_leaf then
      --local back = RayCaster.get_front_leave_ids(node.back, visited)
      --for i = 1, #back do
        --table.insert(ids, back[i])
      --end
    --end
  --end

  if node.parent ~= nil then
    local parent = RayCaster.get_front_leave_ids(node.parent, visited)
    for i = 1, #parent do
      table.insert(ids, parent[i])
    end
  end
 
  return ids
end

RayCaster.get_bounding_line_ids = function(node, visited)
  if visited == nil then
    visited = {}
  end

  visited[node.id] = true
 
  local ids = {}
  if not node.is_leaf then
    if visited[node.front.id] == nil then
      if not node.front.is_leaf then
        local front = RayCaster.get_bounding_line_ids(node.front, visited)
        for i = 1, #front do
          table.insert(ids, front[i])
        end
      end
    end

  --if visited[node.back.id] == nil then
    --if not node.back.is_leaf then
      --local back = RayCaster.get_front_leave_ids(node.back, visited)
      --for i = 1, #back do
        --table.insert(ids, back[i])
      --end
    --end
  --end
  end

  if node.parent ~= nil then
    local parent = RayCaster.get_bounding_line_ids(node.parent, visited)
    for i = 1, #parent do
      table.insert(ids, parent[i])
    end
  end
 
  return ids
end


return RayCaster
