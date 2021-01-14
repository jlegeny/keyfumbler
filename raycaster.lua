local Line = require 'line'
local lines = require 'lines'

local RayCaster = {}

local INTERSECT_TOLERANCE = 0.001
local BSP_TOLERANCE = 0.001

function vector_intersects_line(vector, line)
  local norm_x, norm_y = Line.fast_norm(vector)
  local dota = (line.ax - vector.ax) * norm_x + (line.ay - vector.ay) * norm_y
  local dotb = (line.bx - vector.ax) * norm_x + (line.by - vector.ay) * norm_y

  local norm_xl, norm_yl = Line.fast_norm(line)
  local dot = (vector.ax - line.ax) * norm_xl + (vector.ay - line.ay) * norm_yl
  return (dota < INTERSECT_TOLERANCE and dotb > -INTERSECT_TOLERANCE) and dot > INTERSECT_TOLERANCE
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

RayCaster.fast_collisions = function(map, vector)
  local nodes = RayCaster.get_visible_ordered_nodes(map.volatile.bsp, vector.ax, vector.ay, vector.bx, vector.by)

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
        local region = RayCaster.get_region_node(map.volatile.bsp, hx, hy)
        local room = map:room_node(region)
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
          local wall = map.walls[node.ogid]
          if wall and #wall.decals > 0 then
            local cdec = {}
            local spanx = node.line.bx - node.line.ax
            local spany = node.line.by - node.line.ay
            local posx
            if spanx > spany then
              posx = (int_x - node.line.ax) / spanx
            else
              posx = (int_y - node.line.ay) / spany
            end
            for _, decal in ipairs(wall.decals) do
              if posx > decal.x and posx < decal.x + decal.width then
                table.insert(cdec, {
                  name = decal.name,
                  posx = (posx - decal.x) / decal.width,
                  y = decal.y,
                  height = decal.height,
                })
              end
            end
            collisions[#collisions].decals = cdec
          end
          return collisions
        end
      end
    end
  end
  return collisions
end

RayCaster.is_cut_by_wall = function(map, line)
  local collisions = RayCaster.fast_collisions(map, line)
  if #collisions == 0 then
    return false
  end
  local lc = collisions[#collisions]
  if lc.is_split then
    return false
  end

  return Line.fast_dot(map.walls[lc.id].line, line.bx, line.by) < -0.001
end

RayCaster.is_cut_by_any_line = function(map, line)
  local minx = math.min(line.ax, line.bx) - INTERSECT_TOLERANCE
  local miny = math.min(line.ay, line.by) - INTERSECT_TOLERANCE
  local maxx = math.max(line.ax, line.bx) + INTERSECT_TOLERANCE
  local maxy = math.max(line.ay, line.by) + INTERSECT_TOLERANCE

  local collisions = RayCaster.fast_collisions(map, line)
  for _, c in ipairs(collisions) do
    if c.x >= minx and c.x <= maxx and c.y >= miny and c.y <= maxy then
      return true
    end
  end

  local collisions = RayCaster.fast_collisions(map, lines.swapped(line))
  for _, c in ipairs(collisions) do
    if c.x >= minx and c.x <= maxx and c.y >= miny and c.y <= maxy then
      return true
    end
  end

  return false
end


RayCaster.light_at = function(map, x, y)
  local l = 0
  for id, light in pairs(map.lights) do
    local sqd = (x - light.x) ^ 2 + (y - light.y) ^ 2
    if sqd < light.intensity * 2 then
      if x == light.x and y == light.y then
        l = l + light.intensity
      elseif not RayCaster.is_cut_by_wall(map, Line(light.x, light.y, x, y)) then
        l = l + light.intensity / math.sqrt(sqd)
      end
    end
  end
  return l
end

local LIGHT_CACHE_DENSITY = 20
RayCaster.cached_light_at = function(map, x, y, cache)
  local ux, uy = math.floor(x * LIGHT_CACHE_DENSITY), math.floor(y * LIGHT_CACHE_DENSITY)
  if cache[ux] == nil or cache[ux][uy] == nil then
    if cache[ux] == nil then
      cache[ux] = {}
    end
    cache[ux][uy] = RayCaster.light_at(map, x, y)
  else
  end
  return cache[ux][uy]
end

RayCaster.extended_collisions = function(map, vector)
  local collisions = RayCaster.fast_collisions(map, vector)
  -- light collisions
  local collisions_and_spots = {}
  local spot_ds = {0.1, 0.25, 0.5, 0.75, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5}
  --local spot_ds = {1.6^-1, 1.6^-0.5, 1.6^0, 1.6^0.25, 1.6^0.5, 1.6^2, 1.6^3, 1.6^4 }
  --local spot_ds = {0.6, 0.8, 1, 2, 4}
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

RayCaster.extended_collisions_with_light = function(map, vector, light_cache)
  local collisions = RayCaster.extended_collisions(map, vector)
  for _, c in ipairs(collisions) do
    local dynamic_light = RayCaster.cached_light_at(map, c.x, c.y, light_cache)
    c.dynamic_light = dynamic_light
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
  if dot > -BSP_TOLERANCE or dotv > dot then
    front = RayCaster.get_visible_ordered_nodes(node.front, rx, ry, vx, vy)
  end
  local back = {}
  if dot < BSP_TOLERANCE or dotv < dot then
    back = RayCaster.get_visible_ordered_nodes(node.back, rx, ry, vx, vy)
  end

  local ids = {}
  if dot > BSP_TOLERANCE then
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

function sq_dist_pt_line(line, x, y)
  local abx, aby = line.bx - line.ax, line.by - line.ay
  local apx, apy = x - line.ax, y - line.ay
  local bpx, bpy = x - line.bx, y - line.by

  local e = apx * abx + apy * aby

  if e <= 0 then
    return apx * apx + apy * apy
  end

  local f = abx * abx + aby * aby
  if e >= f then
    return bpx * bpx + bpy * bpy
  end

  return apx * apx + apy * apy - e * e / f
end

RayCaster.circular_collision = function(node, x, y, r2)
  if node.is_leaf then
    return nil
  end

  --local norm_x, norm_y = Line.norm_vector(node.line)
  local dot = Line.point_dot(node.line, x, y)
  
  if node.is_split then
    if dot > 0 then
      return RayCaster.circular_collision(node.front, x, y, r2)
    else
      return RayCaster.circular_collision(node.back, x, y, r2)
    end
  else
    local d = sq_dist_pt_line(node.line, x, y)
    if d <= r2 then
      return node
    end
    if dot > 0 then
      return RayCaster.circular_collision(node.front, x, y, r2)
    else
      return RayCaster.circular_collision(node.back, x, y, r2)
    end
  end
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
