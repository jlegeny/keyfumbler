local lines = require 'lines'
local Line = require 'line'
local Wall = require 'wall'

local EPSILON = 0.001

local Map = {}
Map.__index = Map

setmetatable(Map, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

local function get_index_by_id(tab, id)
  for i, v in ipairs (tab) do
    if (v.id == id) then
      return i
    end
  end
end

function Map.new(params)
  if params == nil then
    params = {
      next_id = 1
    }
  end
  local self = {}
  setmetatable(self, Map)
  self.next_id = params.next_id
  self.walls = {}
  self.bsp = {}
  self:update_bsp()
  return self
end

function Map:from(other)
  self.next_id = other.next_id
  self.walls = other.walls
end

function Map:add_wall(id, wall)
  self.walls[id] = wall
  self:update_bsp()
end

function Map:remove_objects_set(objects)
  for id, kind in pairs(objects) do
    self:remove_object(id, kind)
  end
end

function Map:remove_object(id, kind)
  local kinds
  if kind == nil then
    kinds = { 'wall' }
  else
    kinds = { kind }
  end

  for _, k in ipairs(kinds) do
    if kind == 'wall' then
      self.walls[id] = nil
    end
  end

  self:update_bsp()
end

function Map:get_id()
  local ret = self.next_id
  self.next_id = self.next_id + 1
  return ret
end

function is_point_in(x, y, rect)
  ax = math.min(rect.ax, rect.bx)
  ay = math.min(rect.ay, rect.by)
  bx = math.max(rect.ax, rect.bx)
  by = math.max(rect.ay, rect.by)
  return x >= ax and x <= bx and y >= ay and y <= by
end

function is_line_in(line, rect)
  return is_point_in(line.ax, line.ay, rect) and is_point_in(line.bx, line.by, rect)
end

function Map:bound_objects_set(rect)
  local objects = {}
  for id, wall in pairs(self.walls) do
    if is_line_in(wall.line, rect) then
      objects[id] = 'wall'
    end
  end
  return objects
end

function interp(s, tab)
  return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end
getmetatable("").__mod = interp

function place_in_bsp(node, ogid, wall, next_id)
  if node.is_leaf then
    local new_node = {
      id = next_id(),
      parent = node.parent,
      ogid = ogid,
      wall = Wall(wall.line), 
    }
    local front = {
      is_leaf = true,
      id = next_id(),
      parent = new_node,
    }
    local back = {
      is_leaf = true,
      id = next_id(),
      parent = new_node,
    }
    new_node.front = front
    new_node.back = back
    return new_node
  else
    local dota = Line.point_dot(node.wall.line, wall.line.ax, wall.line.ay)
    local dotb = Line.point_dot(node.wall.line, wall.line.bx, wall.line.by)
    --print('inserting (${ax}, ${ay}, ${bx}, ${by})' % {
    --  ax = wall.line.ax, ay = wall.line.ay, bx = wall.line.bx, by = wall.line.by,
    --})
    --print('comparing to (${ax}, ${ay}, ${bx}, ${by})' % {
    --  ax = node.wall.line.ax, ay = node.wall.line.ay,
    --  bx = node.wall.line.bx, by = node.wall.line.by,
    --})
    --print('dota ${dota} dotb ${dotb}' % {
    --  dota = dota, dotb = dotb
    --})
    if dota < EPSILON and dotb < EPSILON then
      --print('wall ${ogid} is back of ${nid} (${nogid})' % {
      --  ogid = ogid, nid = node.id, nogid = node.ogid
      --})
      node.back = place_in_bsp(node.back, ogid, wall, next_id)
    elseif dota > -EPSILON and dotb > -EPSILON then
      --print('wall ${ogid} is front of ${nid} (${nogid})' % {
      --  ogid = ogid, nid = node.id, nogid = node.ogid
      --})
      node.front = place_in_bsp(node.front, ogid, wall, next_id)
    else
      local sx, sy = lines.intersection(wall.line, node.wall.line)
      --print('wall ${ogid} needs to be split at ${x}, ${y}' % {
      --  ogid = ogid,  x = sx, y = sy
      --})
      local split1 = Line(wall.line.ax, wall.line.ay, sx, sy)
      local split2 = Line(sx, sy, wall.line.bx, wall.line.by)
      node = place_in_bsp(node, ogid, Wall(split1), next_id)
      node = place_in_bsp(node, ogid, Wall(split2), next_id)
    end
    return node
  end
end

function print_bsp(node, depth)
  local str = ''
  for i = 1, depth do
    str = str .. '  '
  end
  local parent_id
  if node.parent == nil then
    parent_id = 'nil'
  else
    parent_id = node.parent.id
  end
  if node.is_leaf then
    str = str .. 'leaf ' .. node.id .. ' parent ' .. parent_id
    print(str)
  else
    str = str .. 'node ' .. node.id .. ' parent ' .. parent_id .. '  w: ' .. node.ogid
    print(str)
    print_bsp(node.front, depth + 1)
    print_bsp(node.back, depth + 1)
  end
end

function Map:update_bsp()
  local bsp_id = 0

  function next_id()
    bsp_id = bsp_id + 1
    return bsp_id
  end

  self.bsp = {
    id = bsp_id,
    is_leaf = true,
    parent = nil,
  }

  
  local sorted_ids = {}
  for k, _ in pairs(self.walls) do
    table.insert(sorted_ids, k)
  end
  table.sort(sorted_ids)

  for i, ogid in ipairs(sorted_ids) do
    local wall = self.walls[ogid]
    self.bsp = place_in_bsp(self.bsp, ogid, wall, next_id)
  end
  print('-- BSP --')
  print_bsp(self.bsp, 0)
  print()

end

return Map
